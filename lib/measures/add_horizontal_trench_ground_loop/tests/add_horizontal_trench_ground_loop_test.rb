require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class AddHorizontalTrenchGroundLoopTest < Minitest::Test
  F2C = lambda { |f| (f - 32.0) / 1.8 }

  # An unconnected EIR heat pump tagged as water source, as Create
  # Water-to-Water Heat Pump makes it, with a 200 gpm source flow.
  def tagged_heat_pump(model, name = 'WWHP 1')
    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    hp.setName(name)
    hp.setSourceSideReferenceFlowRate(200.0 * 6.30902e-5)
    hp.additionalProperties.setFeature('IntendedCondenserType', 'WaterSource')
    hp
  end

  def run_measure(model, args_hash = {})
    measure = AddHorizontalTrenchGroundLoop.new
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

  def test_arguments_list_heat_pumps
    model = OpenStudio::Model::Model.new
    tagged_heat_pump(model)
    air = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    air.setName('Air HP')
    choices = AddHorizontalTrenchGroundLoop.new.arguments(model)[0]
    assert_equal([AddHorizontalTrenchGroundLoop::FIRST_HP, 'Air HP', 'WWHP 1'].sort, choices.choiceValues.to_a.sort)
    labels = choices.choiceValueDisplayNames.to_a
    assert_includes(labels, 'WWHP 1 (HeatPump:PlantLoop:EIR:Heating)')
    assert_includes(labels, 'Air HP (HeatPump:PlantLoop:EIR:Heating, now air source)')
  end

  def test_ground_loop_defaults
    model = OpenStudio::Model::Model.new
    hp = tagged_heat_pump(model)
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    assert_equal(0, result.warnings.size)
    gl = hp.secondaryPlantLoop.get
    assert_equal('Ground Loop', gl.name.to_s)
    assert_equal('WaterSource', hp.condenserType)
    assert_equal('PropyleneGlycol', gl.fluidType)
    assert_equal(25, gl.glycolConcentration)
    assert_equal('Condenser', gl.sizingPlant.loopType)
    assert_in_delta(F2C.call(45.0), gl.sizingPlant.designLoopExitTemperature, 1e-9)
    ghx = model.getGroundHeatExchangerHorizontalTrenchs.first
    assert_equal(gl.handle, ghx.plantLoop.get.handle)
    assert_in_delta(200.0 * 6.30902e-5, ghx.designFlowRate, 1e-12)
    assert_equal(32, ghx.numberofTrenches)
    assert_in_delta(457.2, ghx.trenchLengthinPipeAxialDirection, 1e-9)
    assert_in_delta(1.2, ghx.soilThermalConductivity, 1e-3)
    assert_in_delta(1700.0, ghx.soilDensity, 0.5)
    assert_in_delta(1400.0, ghx.soilSpecificHeat, 1.0)
    assert_in_delta(0.0422, ghx.pipeOuterDiameter, 1e-4)
    gtm = ghx.undisturbedGroundTemperatureModel.to_SiteGroundTemperatureUndisturbedKusudaAchenbach.get
    assert_in_delta(F2C.call(45.0), gtm.averageSoilSurfaceTemperature.get, 1e-9)
    assert_equal(1, model.getSiteGroundTemperatureUndisturbedKusudaAchenbachs.size)
    pump = model.getPumpConstantSpeeds.first
    assert_in_delta(17.5 * 745.7, pump.ratedPowerConsumption.get, 1e-6)
    assert_equal('Intermittent', pump.pumpControlType)
    assert_equal(1, gl.supplyOutletNode.setpointManagers.size)
    # The load side is left alone.
    assert(hp.plantLoop.empty?)
  end

  def test_untagged_air_source_only_by_name
    model = OpenStudio::Model::Model.new
    air = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    air.setName('Air HP')
    air.setSourceSideReferenceFlowRate(0.01)
    # Not picked as "first water-source heat pump".
    assert_equal('Fail', run_measure(model).value.valueName)
    result = run_measure(model, 'hp_name' => 'Air HP', 'glycol_pct' => 0.0)
    assert_equal('Success', result.value.valueName)
    assert_equal(1, result.warnings.size)
    assert_equal('WaterSource', air.condenserType)
    assert_equal('Water', air.secondaryPlantLoop.get.fluidType)
  end

  def test_autosized_source_flow_needs_design_flow
    model = OpenStudio::Model::Model.new
    eqfit = OpenStudio::Model::HeatPumpWaterToWaterEquationFitHeating.new(model)
    eqfit.setName('EqFit HP')
    assert_equal('Fail', run_measure(model).value.valueName)
    assert(eqfit.secondaryPlantLoop.empty?)
    result = run_measure(model, 'design_flow_gpm' => 300.0)
    assert_equal('Success', result.value.valueName)
    assert_equal('Ground Loop', eqfit.secondaryPlantLoop.get.name.to_s)
    assert_in_delta(300.0 * 6.30902e-5, model.getGroundHeatExchangerHorizontalTrenchs.first.designFlowRate, 1e-12)
  end

  def test_duplicate_loop_name_fails
    model = OpenStudio::Model::Model.new
    tagged_heat_pump(model)
    OpenStudio::Model::PlantLoop.new(model).setName('Ground Loop')
    assert_equal('Fail', run_measure(model).value.valueName)
  end
end
