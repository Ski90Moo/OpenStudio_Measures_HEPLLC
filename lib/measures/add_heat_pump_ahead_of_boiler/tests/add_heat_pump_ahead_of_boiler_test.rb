require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class AddHeatPumpAheadOfBoilerTest < Minitest::Test
  F2C = lambda { |f| (f - 32.0) / 1.8 }

  # Hot water loop with a boiler and one unconnected air-source heat pump.
  # control: :reset (148F at 0F OA to 110F at 60F OA), :constant (148F
  # ScheduleConstant), :ruleset (148F/120F ScheduleRuleset) or :none.
  def build_model(control: :reset)
    model = OpenStudio::Model::Model.new
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName('HW Loop')
    OpenStudio::Model::PumpVariableSpeed.new(model).addToNode(loop.supplyInletNode)
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName('Boiler 1')
    loop.addSupplyBranchForComponent(boiler)
    case control
    when :reset
      oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      oar.setControlVariable('Temperature')
      oar.setSetpointatOutdoorLowTemperature(F2C.call(148.0))
      oar.setOutdoorLowTemperature(F2C.call(0.0))
      oar.setSetpointatOutdoorHighTemperature(F2C.call(110.0))
      oar.setOutdoorHighTemperature(F2C.call(60.0))
      oar.addToNode(loop.supplyOutletNode)
    when :constant
      sched = OpenStudio::Model::ScheduleConstant.new(model)
      sched.setName('HW Temp')
      sched.setValue(F2C.call(148.0))
      OpenStudio::Model::SetpointManagerScheduled.new(model, sched).addToNode(loop.supplyOutletNode)
    when :ruleset
      # Default day: 148F until 06:00, then 120F. Weekend rule: 100F all day.
      sched = OpenStudio::Model::ScheduleRuleset.new(model)
      sched.setName('HW Temp')
      day = sched.defaultDaySchedule
      day.clearValues
      day.addValue(OpenStudio::Time.new(0, 6, 0, 0), F2C.call(148.0))
      day.addValue(OpenStudio::Time.new(0, 24, 0, 0), F2C.call(120.0))
      rule = OpenStudio::Model::ScheduleRule.new(sched)
      rule.setApplySaturday(true)
      rule.setApplySunday(true)
      rule.daySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), F2C.call(100.0))
      winter = OpenStudio::Model::ScheduleDay.new(model)
      winter.addValue(OpenStudio::Time.new(0, 24, 0, 0), F2C.call(160.0))
      sched.setWinterDesignDaySchedule(winter)
      OpenStudio::Model::SetpointManagerScheduled.new(model, sched).addToNode(loop.supplyOutletNode)
    end
    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    hp.setName('HP 1')
    hp.setCondenserType('AirSource')
    # 113F maximum, as the create heat pump measures set it.
    hp.setMaximumSupplyWaterTemperatureCurve(constant_curve(model, F2C.call(113.0)))
    model
  end

  def constant_curve(model, value_c)
    c = OpenStudio::Model::CurveQuadratic.new(model)
    c.setCoefficient1Constant(value_c)
    c.setCoefficient2x(0.0)
    c.setCoefficient3xPOW2(0.0)
    c.setMinimumValueofx(-50.0)
    c.setMaximumValueofx(60.0)
    c
  end

  def hp_reset(model)
    hp_setpoint_manager(model).to_SetpointManagerOutdoorAirReset.get
  end

  def hp_setpoint_manager(model)
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    spms = hp.supplyOutletModelObject.get.to_Node.get.setpointManagers
    assert_equal(1, spms.size)
    spms.first
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
    assert_equal(5, arguments.size)
    assert_equal(['Bypass', 'Loop flow'], arguments[4].choiceValues.to_a)
    assert_equal('Bypass', arguments[4].defaultValueAsString)
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

    # No maximum in the model for these types: one must be entered.
    result = run_measure(model, 'hp_name' => 'EqFit HP', 'hp_flow' => 'Loop flow')
    assert_equal('Fail', result.value.valueName)
    assert(eqfit.plantLoop.empty?)

    # Water source with no source loop: connected, with one warning (capacity is fixed).
    result = run_measure(model, 'hp_name' => 'EqFit HP', 'max_lwt_f' => 113.0, 'hp_flow' => 'Loop flow')
    assert_equal('Success', result.value.valueName)
    assert_equal(1, result.warnings.size)
    assert_equal('HW Loop', eqfit.plantLoop.get.name.to_s)
    assert_equal(1, eqfit.supplyOutletModelObject.get.to_Node.get.setpointManagers.size)

    # The first remaining unconnected heat pump is the fuel-fired one; it goes
    # between the equation-fit heat pump and the boiler.
    result = run_measure(model, 'max_lwt_f' => 113.0, 'hp_flow' => 'Loop flow')
    assert_equal('Success', result.value.valueName)
    assert_equal(0, result.warnings.size)
    assert_equal('HW Loop', fuel.plantLoop.get.name.to_s)
    boiler = model.getBoilerHotWaterByName('Boiler 1').get
    assert_equal(fuel.outletModelObject.get.handle, boiler.inletModelObject.get.handle)
    assert_equal(1, fuel.outletModelObject.get.to_Node.get.setpointManagers.size)
  end

  def test_tagged_water_source_without_source_loop_warns
    model = build_model
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    hp.setReferenceCapacity(100000.0)
    hp.additionalProperties.setFeature('IntendedCondenserType', 'WaterSource')
    result = run_measure(model, 'hp_flow' => 'Loop flow')
    assert_equal('Success', result.value.valueName)
    assert_equal(1, result.warnings.size)
    assert(result.warnings.first.logMessage.include?('water source'))
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

  def test_loop_maximum_caps_reset
    model = build_model
    # Loop maximum 105F, below the 113F heat pump maximum and the whole reset.
    model.getPlantLoopByName('HW Loop').get.setMaximumLoopTemperature(F2C.call(105.0))
    assert_equal('Success', run_measure(model).value.valueName)
    spm = hp_setpoint_manager(model).to_SetpointManagerOutdoorAirReset.get
    assert_in_delta(F2C.call(105.0), spm.setpointatOutdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call(105.0), spm.setpointatOutdoorHighTemperature, 1e-6)
    assert_in_delta(F2C.call(0.0), spm.outdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call(60.0), spm.outdoorHighTemperature, 1e-6)
  end

  def test_constant_schedule
    model = build_model(control: :constant)
    assert_equal('Success', run_measure(model).value.valueName)
    spm = hp_setpoint_manager(model).to_SetpointManagerScheduled.get
    assert_equal('Temperature', spm.controlVariable)
    sched = spm.schedule.to_ScheduleConstant.get
    assert_in_delta(F2C.call(113.0), sched.value, 1e-6)
    assert_in_delta(F2C.call(148.0), model.getScheduleConstantByName('HW Temp').get.value, 1e-6)

    # Below the cap the heat pump follows the loop.
    model = build_model(control: :constant)
    model.getScheduleConstantByName('HW Temp').get.setValue(F2C.call(100.0))
    assert_equal('Success', run_measure(model).value.valueName)
    sched = hp_setpoint_manager(model).to_SetpointManagerScheduled.get.schedule.to_ScheduleConstant.get
    assert_in_delta(F2C.call(100.0), sched.value, 1e-6)
  end

  def test_ruleset_schedule
    model = build_model(control: :ruleset)
    loop_sched = model.getScheduleRulesetByName('HW Temp').get
    assert_equal('Success', run_measure(model, 'boiler_control' => 'Setpoint').value.valueName)
    sched = hp_setpoint_manager(model).to_SetpointManagerScheduled.get.schedule.to_ScheduleRuleset.get
    refute_equal(loop_sched.handle, sched.handle)
    default = sched.defaultDaySchedule.values.to_a
    assert_in_delta(F2C.call(113.0), default[0], 1e-6)
    assert_in_delta(F2C.call(113.0), default[1], 1e-6)
    assert_equal(1, sched.scheduleRules.size)
    assert_in_delta(F2C.call(100.0), sched.scheduleRules.first.daySchedule.values.to_a[0], 1e-6)
    assert_in_delta(F2C.call(113.0), sched.winterDesignDaySchedule.values.to_a[0], 1e-6)
    # The loop schedule is unchanged.
    assert_in_delta(F2C.call(148.0), loop_sched.defaultDaySchedule.values.to_a[0], 1e-6)
    assert_in_delta(F2C.call(160.0), loop_sched.winterDesignDaySchedule.values.to_a[0], 1e-6)
    assert_in_delta(F2C.call(100.0), loop_sched.scheduleRules.first.daySchedule.values.to_a[0], 1e-6)
    # Setpoint trim: the boiler follows the loop's own schedule.
    boiler = model.getBoilerHotWaterByName('Boiler 1').get
    b_spm = boiler.outletModelObject.get.to_Node.get.setpointManagers.first.to_SetpointManagerScheduled.get
    assert_equal(loop_sched.handle, b_spm.schedule.handle)
  end

  def test_unsupported_control_fails
    model = build_model(control: :none)
    assert_equal('Fail', run_measure(model).value.valueName)
    assert(model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.plantLoop.empty?)

    model = build_model(control: :none)
    OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model).addToNode(model.getPlantLoopByName('HW Loop').get.supplyOutletNode)
    assert_equal('Fail', run_measure(model).value.valueName)

    model = build_model(control: :none)
    compact = OpenStudio::Model::ScheduleCompact.new(model, F2C.call(148.0))
    OpenStudio::Model::SetpointManagerScheduled.new(model, compact).addToNode(model.getPlantLoopByName('HW Loop').get.supplyOutletNode)
    assert_equal('Fail', run_measure(model).value.valueName)
    assert(model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.plantLoop.empty?)
  end

  def test_entered_maximum_above_heat_pump_maximum
    model = build_model
    result = run_measure(model, 'max_lwt_f' => 130.0)
    assert_equal('Success', result.value.valueName)
    assert(result.warnings.any? { |w| w.logMessage.include?('above') && w.logMessage.include?('113.0F is used') })
    assert_in_delta(F2C.call(113.0), hp_reset(model).setpointatOutdoorLowTemperature, 1e-6)
  end

  def test_entered_maximum_below_heat_pump_maximum
    model = build_model
    result = run_measure(model, 'max_lwt_f' => 105.0)
    assert_equal('Success', result.value.valueName)
    refute(result.warnings.any? { |w| w.logMessage.include?('is used') })
    assert_in_delta(F2C.call(105.0), hp_reset(model).setpointatOutdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call(105.0), hp_reset(model).setpointatOutdoorHighTemperature, 1e-6)
  end

  def test_capacity_curve_limit_without_maximum_curve
    model = build_model
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    hp.resetMaximumSupplyWaterTemperatureCurve
    hp.capacityModifierFunctionofTemperatureCurve.to_CurveBiquadratic.get.setMaximumValueofx(F2C.call(120.0))
    assert_equal('Success', run_measure(model).value.valueName)
    spm = hp_reset(model)
    assert_in_delta(F2C.call(120.0), spm.setpointatOutdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call((148.0 - 120.0) / (148.0 - 110.0) * 60.0), spm.outdoorLowTemperature, 1e-6)
  end

  def ems_program_lines(model)
    progs = model.getEnergyManagementSystemPrograms
    assert_equal(1, progs.size)
    progs.first.lines.to_a.map(&:strip)
  end

  def test_maximum_curve_varying_with_outdoor_temperature
    model = build_model
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    # 40C + 0.2 x OAT over -20C..20C: 36C to 44C.
    c = OpenStudio::Model::CurveQuadratic.new(model)
    c.setName('Varying Max')
    c.setCoefficient1Constant(40.0)
    c.setCoefficient2x(0.2)
    c.setCoefficient3xPOW2(0.0)
    c.setMinimumValueofx(-20.0)
    c.setMaximumValueofx(20.0)
    hp.setMaximumSupplyWaterTemperatureCurve(c)
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    # The setpoint manager is capped at the curve's highest value; EMS applies
    # the curve each timestep.
    assert_in_delta(44.0, hp_reset(model).setpointatOutdoorLowTemperature, 1e-6)
    lines = ems_program_lines(model)
    assert_equal('SET mx = @CurveValue HP_1_Max_Curve HP_1_Source_T', lines[0])
    assert_equal('SET HP_1_SP = sp', lines.last)
    idx = model.getEnergyManagementSystemCurveOrTableIndexVariables.first
    assert_equal('Varying Max', idx.curveOrTableObject.name.to_s)
    act = model.getEnergyManagementSystemActuators.first
    assert_equal(hp.supplyOutletModelObject.get.handle, act.actuatedComponent.get.handle)
    assert_equal('Temperature Setpoint', act.actuatedComponentControlType)
    sensors = model.getEnergyManagementSystemSensors.map { |x| [x.outputVariableOrMeterName, x.keyName] }.sort
    expected = [['Heat Pump Source Side Inlet Temperature', 'HP 1'],
                ['System Node Setpoint Temperature', model.getPlantLoopByName('HW Loop').get.supplyOutletNode.name.to_s]].sort
    assert_equal(expected, sensors)
    pcm = model.getEnergyManagementSystemProgramCallingManagers.first
    assert_equal('AfterPredictorAfterHVACManagers', pcm.callingPoint)
  end

  def uca_table(model)
    iv = OpenStudio::Model::TableIndependentVariable.new(model)
    iv.setValues([17.0, 19.0, 40.0].map { |f| F2C.call(f) })
    t = OpenStudio::Model::TableLookup.new(model)
    t.setName('UCA Max')
    t.addIndependentVariable(iv)
    t.setOutputValues([110.9, 113.0, 135.0].map { |f| F2C.call(f) })
    t
  end

  def test_table_lookup_maximum
    model = build_model
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    hp.setMaximumSupplyWaterTemperatureCurve(uca_table(model))
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    assert(result.info.any? { |m| m.logMessage.include?('110.9F to 135.0F') })
    # 148F@0F to 110F@60F capped at 135F: crosses at 20.53F OA.
    spm = hp_reset(model)
    assert_in_delta(F2C.call(135.0), spm.setpointatOutdoorLowTemperature, 1e-6)
    assert_in_delta(F2C.call((148.0 - 135.0) / (148.0 - 110.0) * 60.0), spm.outdoorLowTemperature, 1e-6)
    lines = ems_program_lines(model)
    # The loop maximum temperature is the fixed limit.
    assert_includes(lines, "IF sp > #{format('%.4f', model.getPlantLoopByName('HW Loop').get.maximumLoopTemperature)}")

    # An entered maximum below the whole table: a fixed cap, no EMS.
    model = build_model
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    hp.setMaximumSupplyWaterTemperatureCurve(uca_table(model))
    assert_equal('Success', run_measure(model, 'max_lwt_f' => 105.0).value.valueName)
    assert(model.getEnergyManagementSystemPrograms.empty?)
    assert_in_delta(F2C.call(105.0), hp_reset(model).setpointatOutdoorLowTemperature, 1e-6)
  end

  def test_bypass_holds_heat_pump_flow
    model = build_model
    loop = model.getPlantLoopByName('HW Loop').get
    # Boiler on the supply outlet run, so the whole loop flow passes it.
    model.getBoilerHotWaterByName('Boiler 1').get.remove
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName('Boiler 1')
    boiler.addToNode(loop.supplyOutletNode)
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get
    hp.setReferenceCapacity(100000.0)
    hp.setLoadSideReferenceFlowRate(150.3 * 6.30902e-5)
    hp.setFlowMode('VariableSpeedPumping')
    loop.addDemandBranchForComponent(OpenStudio::Model::CoilHeatingWater.new(model))
    refute(AddHeatPumpAheadOfBoiler.new.demand_bypass?(loop))
    demand_branches = loop.demandSplitter.outletModelObjects.size
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    assert_in_delta(150.3 * 6.30902e-5, loop.minimumLoopFlowRate.get, 1e-12)
    # Autosized maximum: fixed at the heat pump flow, with a warning.
    assert_in_delta(150.3 * 6.30902e-5, loop.maximumLoopFlowRate.get, 1e-12)
    assert(result.warnings.any? { |w| w.logMessage.include?('maximum flow was autosized') })
    # The autosized pump is fixed at the loop maximum.
    assert_in_delta(150.3 * 6.30902e-5, model.getPumpVariableSpeeds.first.ratedFlowRate.get, 1e-12)
    refute(result.warnings.any? { |w| w.logMessage.include?('in parallel with other equipment') })
    assert_equal('ConstantFlow', hp.flowMode)
    assert_equal(demand_branches + 1, loop.demandSplitter.outletModelObjects.size)
    assert(model.getPipeAdiabaticByName('HW Loop Minimum Flow Bypass').is_initialized)

    # A loop that already has a demand bypass and a larger maximum keeps them.
    # A pipe-only supply bypass in parallel is not warned about.
    model = build_model
    loop = model.getPlantLoopByName('HW Loop').get
    loop.addDemandBranchForComponent(OpenStudio::Model::PipeAdiabatic.new(model))
    loop.addSupplyBranchForComponent(OpenStudio::Model::PipeAdiabatic.new(model))
    loop.setMaximumLoopFlowRate(0.02)
    model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.setLoadSideReferenceFlowRate(0.01)
    branches = loop.demandSplitter.outletModelObjects.size
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    assert_equal(branches, loop.demandSplitter.outletModelObjects.size)
    assert_in_delta(0.02, loop.maximumLoopFlowRate.get, 1e-12)
    assert_in_delta(0.01, loop.minimumLoopFlowRate.get, 1e-12)
    assert_in_delta(0.02, model.getPumpVariableSpeeds.first.ratedFlowRate.get, 1e-12)
    refute(result.warnings.any? { |w| w.logMessage.include?('in parallel with other equipment') })

    # A second boiler on a parallel branch shares the flow: warned.
    model = build_model
    loop = model.getPlantLoopByName('HW Loop').get
    loop.addSupplyBranchForComponent(OpenStudio::Model::BoilerHotWater.new(model))
    model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.setLoadSideReferenceFlowRate(0.01)
    result = run_measure(model, 'boiler_name' => 'Boiler 1')
    assert_equal('Success', result.value.valueName)
    assert(result.warnings.any? { |w| w.logMessage.include?('in parallel with other equipment') })

    # Loop flow: nothing changes.
    model = build_model
    loop = model.getPlantLoopByName('HW Loop').get
    model.getHeatPumpPlantLoopEIRHeatingByName('HP 1').get.setLoadSideReferenceFlowRate(0.01)
    branches = loop.demandSplitter.outletModelObjects.size
    assert_equal('Success', run_measure(model, 'hp_flow' => 'Loop flow').value.valueName)
    assert_equal(branches, loop.demandSplitter.outletModelObjects.size)
    assert(loop.isMaximumLoopFlowRateAutosized)
    assert(model.getPumpVariableSpeeds.first.isRatedFlowRateAutosized)
    assert(loop.minimumLoopFlowRate.empty? || loop.minimumLoopFlowRate.get == 0.0)
  end

  def test_negative_maximum_fails
    model = build_model
    assert_equal('Fail', run_measure(model, 'max_lwt_f' => -5.0).value.valueName)
  end
end
