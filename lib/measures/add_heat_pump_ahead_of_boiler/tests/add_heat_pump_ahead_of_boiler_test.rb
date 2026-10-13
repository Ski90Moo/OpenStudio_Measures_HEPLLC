require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class AddHeatPumpAheadOfBoilerTest < Minitest::Test
  F2C = lambda { |f| (f - 32.0) / 1.8 }

  # Hot water loop with a boiler, an outdoor air reset (148F at 0F OA to
  # 110F at 60F OA) and one unconnected air-source heat pump.
  def build_model(with_reset: true)
    model = OpenStudio::Model::Model.new
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName('HW Loop')
    OpenStudio::Model::PumpVariableSpeed.new(model).addToNode(loop.supplyInletNode)
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName('Boiler 1')
    loop.addSupplyBranchForComponent(boiler)
    if with_reset
      oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      oar.setControlVariable('Temperature')
      oar.setSetpointatOutdoorLowTemperature(F2C.call(148.0))
      oar.setOutdoorLowTemperature(F2C.call(0.0))
      oar.setSetpointatOutdoorHighTemperature(F2C.call(110.0))
      oar.setOutdoorHighTemperature(F2C.call(60.0))
      oar.addToNode(loop.supplyOutletNode)
    end
    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    hp.setName('HP 1')
    hp.setCondenserType('AirSource')
    model
  end

  def run_measure(model, args_hash = {})
    measure = AddHeatPumpAheadOfBoiler.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    arguments.each do |arg|
      temp_arg_var = arg.clone
      assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash.key?(arg.name)
      argument_map[arg.name] = temp_arg_var
    end
    measure.run(model, runner, argument_map)
    result = runner.result
    result.showOutput
    result
  end

  def test_arguments_list_model_objects
    model = build_model
    arguments = AddHeatPumpAheadOfBoiler.new.arguments(model)
    assert_equal(4, arguments.size)
    assert_equal([AddHeatPumpAheadOfBoiler::FIRST_HP, 'HP 1'], arguments[0].choiceValues.to_a)
    assert_equal('HP 1 (HeatPump:PlantLoop:EIR:Heating)', arguments[0].choiceValueDisplayNames.to_a[1])
    assert_equal(AddHeatPumpAheadOfBoiler::FIRST_HP, arguments[0].defaultValueAsString)
    assert_equal(['Boiler 1'], arguments[1].choiceValues.to_a)
  end

  def test_other_heat_pump_types
    model = build_model
    model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.remove
    eqfit = OpenStudio::Model::HeatPumpWaterToWaterEquationFitHeating.new(model)
    eqfit.setName('EqFit HP')
    eqfit.setRatedHeatingCapacity(100000.0)
    fuel = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
    fuel.setName('Fuel HP')
    fuel.setNominalHeatingCapacity(100000.0)
    awhp = OpenStudio::Model::HeatPumpAirToWater.new(model)
    awhp.setHeatingOperationMode(OpenStudio::Model::HeatPumpAirToWaterHeating.new(model))
    choices = AddHeatPumpAheadOfBoiler.new.arguments(model)[0].choiceValues.to_a
    # HeatPump:AirToWater is not offered (OpenStudio 3.11 translator crash).
    assert_equal([AddHeatPumpAheadOfBoiler::FIRST_HP, 'EqFit HP', 'Fuel HP'], choices)

    # Water source with no source loop: connected, with one warning (capacity is fixed).
    result = run_measure(model, 'hp_name' => 'EqFit HP')
    assert_equal('Success', result.value.valueName)
    assert_equal(1, result.warnings.size)
    assert_equal('HW Loop', eqfit.plantLoop.get.name.to_s)
    assert_equal(1, eqfit.supplyOutletModelObject.get.to_Node.get.setpointManagers.size)

    # The first remaining unconnected heat pump is the fuel-fired one; it goes
    # between the equation-fit heat pump and the boiler.
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    assert_equal(0, result.warnings.size)
    assert_equal('HW Loop', fuel.plantLoop.get.name.to_s)
    boiler = model.getBoilerHotWaterByName('Boiler 1').get
    assert_equal(fuel.outletModelObject.get.handle, boiler.inletModelObject.get.handle)
    assert_equal(1, fuel.outletModelObject.get.to_Node.get.setpointManagers.size)
  end

  def test_no_unconnected_heat_pump_fails
    model = build_model
    model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.remove
    assert_equal('Fail', run_measure(model).value.valueName)
  end

  def test_heat_pump_in_series_ahead_of_boiler
    model = build_model
    boiler = model.getBoilerHotWaterByName('Boiler 1').get
    flow_mode = boiler.boilerFlowMode
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)

    # HP 1 is autosized: warned that the boiler will not trim.
    assert(result.warnings.any? { |w| w.logMessage.include?('autosized') })

    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    assert_equal('HW Loop', hp.plantLoop.get.name.to_s)
    assert_equal('Setpoint', hp.controlType)
    assert_equal(hp.supplyOutletModelObject.get.handle, boiler.inletModelObject.get.handle)

    # 148F@0F to 110F@60F capped at 113F: the cap is reached at 55.26F OA.
    spm = hp.supplyOutletModelObject.get.to_Node.get.setpointManagers.first.to_SetpointManagerOutdoorAirReset.get
    assert_in_delta(F2C.call(113.0), spm.setpointatOutdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call(0.0 + (148.0 - 113.0) / (148.0 - 110.0) * 60.0), spm.outdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call(110.0), spm.setpointatOutdoorHighTemperature, 1e-6)
    # Load trim leaves the boiler as it was.
    assert_equal(flow_mode, boiler.boilerFlowMode)
    assert(boiler.outletModelObject.get.to_Node.get.setpointManagers.empty?)
  end

  def test_setpoint_trim
    model = build_model
    result = run_measure(model, 'boiler_control' => 'Setpoint')
    assert_equal('Success', result.value.valueName)
    boiler = model.getBoilerHotWaterByName('Boiler 1').get
    assert_equal('LeavingSetpointModulated', boiler.boilerFlowMode)
    assert_equal(1, boiler.outletModelObject.get.to_Node.get.setpointManagers.size)
  end

  def test_requires_outdoor_air_reset
    model = build_model(with_reset: false)
    result = run_measure(model)
    assert_equal('Fail', result.value.valueName)
    assert(model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.plantLoop.empty?)
  end
end
