class AddHeatPumpAheadOfBoiler < OpenStudio::Measure::ModelMeasure
  def name
    return "Add Heat Pump Ahead Of Boiler"
  end

  def description
    return "Connects an existing heating heat pump that is not yet on a plant loop (plant loop EIR, water-to-water equation fit, or fuel-fired air-to-water) in series ahead of a hot water boiler, so the heat pump preheats the return water and the boiler trims to the loop supply temperature. The heat pump's leaving water temperature follows the loop's outdoor air reset but is capped at a maximum the heat pump can deliver. Use it after a measure that creates the heat pump, such as Create Air-to-Water Heat Pump, and after the loop has an outdoor air reset, such as from Hot Water Supply Outdoor Air Reset."
  end

  def modeler_description
    return "Supports HeatPumpPlantLoopEIRHeating, HeatPumpWaterToWaterEquationFitHeating and HeatPumpAirToWaterFuelFiredHeating. HeatPumpAirToWater is not supported: in OpenStudio 3.11 the forward translator crashes when a setpoint manager is on its heating mode's outlet node. Adds the selected heat pump at the boiler's inlet node, so it sits in series on the boiler's branch. The loop is the boiler's plant loop, which must have a SetpointManagerOutdoorAirReset on its supply outlet. The heat pump outlet gets a SetpointManagerOutdoorAirReset that equals min(maximum LWT, loop reset): its low-OA point moves to the outdoor temperature where the loop reset crosses the cap. With a setpoint manager on its outlet the heat pump is dispatched by PlantEquipmentOperation:ComponentSetpoint (for the EIR heat pump ControlType is also set to Setpoint; the other types have no such field). Boiler trim control Load leaves the boiler in the load-based heating scheme. Setpoint gives the boiler outlet its own reset matching the loop and sets the boiler flow mode to LeavingSetpointModulated; EnergyPlus then requests design flow continuously, which raises pump energy. A water-source heat pump whose source side is not connected to a condenser loop is reported as a warning."
  end

  FIRST_HP = "First unconnected heat pump"

  # Heating heat pumps not yet on a plant loop, as [name, IDD type, component].
  # HeatPump:AirToWater is left out: in OpenStudio 3.11 the forward translator
  # crashes when its heating mode's outlet node has a setpoint manager.
  def unconnected_heat_pumps(model)
    hps = []
    model.getHeatPumpPlantLoopEIRHeatings.each { |h| hps << [h.name.to_s, 'HeatPump:PlantLoop:EIR:Heating', h] }
    model.getHeatPumpWaterToWaterEquationFitHeatings.each { |h| hps << [h.name.to_s, 'HeatPump:WaterToWater:EquationFit:Heating', h] }
    model.getHeatPumpAirToWaterFuelFiredHeatings.each { |h| hps << [h.name.to_s, 'HeatPump:AirToWater:FuelFired:Heating', h] }
    hps.select { |_, _, c| c.plantLoop.empty? }
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # Choices are the model's heat pumps not yet on a loop, and boilers on a loop.
    # "First unconnected heat pump" lets a workflow pick up a heat pump created
    # by an earlier measure, which is not in the seed model's list.
    hp_names = OpenStudio::StringVector.new
    hp_labels = OpenStudio::StringVector.new
    hp_names << FIRST_HP
    hp_labels << FIRST_HP
    unconnected_heat_pumps(model).each do |n, type, _|
      hp_names << n
      hp_labels << "#{n} (#{type})"
    end
    hp_name = OpenStudio::Measure::OSArgument.makeChoiceArgument("hp_name", hp_names, hp_labels, true)
    hp_name.setDisplayName("Heat pump")
    hp_name.setDescription("Heating heat pump not yet connected to a loop: HeatPump:PlantLoop:EIR:Heating, HeatPump:WaterToWater:EquationFit:Heating, or HeatPump:AirToWater:FuelFired:Heating. 'First unconnected heat pump' takes the first one found when the measure runs, for use after a measure in the same workflow that creates the heat pump.")
    hp_name.setDefaultValue(FIRST_HP)
    args << hp_name
    boiler_names = OpenStudio::StringVector.new
    model.getBoilerHotWaters.select { |b| b.plantLoop.is_initialized }.each { |b| boiler_names << b.name.to_s }
    boiler_name = OpenStudio::Measure::OSArgument.makeChoiceArgument("boiler_name", boiler_names, true)
    boiler_name.setDisplayName("Boiler")
    boiler_name.setDescription("Hot water boiler on a plant loop. The heat pump is inserted at its inlet node.")
    boiler_name.setDefaultValue(boiler_names[0]) unless boiler_names.empty?
    args << boiler_name
    max_lwt_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("max_lwt_f", true)
    max_lwt_f.setDisplayName("Maximum heat pump leaving water temperature (F)")
    max_lwt_f.setDescription("Cap on the heat pump's leaving water setpoint, deg F. Above it the boiler supplies the rest of the loop's reset temperature.")
    max_lwt_f.setDefaultValue(113.0)
    args << max_lwt_f
    boiler_control_choices = OpenStudio::StringVector.new
    boiler_control_choices << "Load"
    boiler_control_choices << "Setpoint"
    boiler_control = OpenStudio::Measure::OSArgument.makeChoiceArgument("boiler_control", boiler_control_choices, boiler_control_choices, true)
    boiler_control.setDisplayName("Boiler trim control")
    boiler_control.setDescription("Load: the boiler stays in the load-based heating scheme and its flow follows coil demand. Setpoint: the boiler gets its own outdoor air reset (component setpoint scheme); EnergyPlus then requests design flow continuously, which raises pump energy.")
    boiler_control.setDefaultValue("Load")
    args << boiler_control
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    hp_name = runner.getStringArgumentValue("hp_name", user_arguments)
    boiler_name = runner.getStringArgumentValue("boiler_name", user_arguments)
    max_lwt_f = runner.getDoubleArgumentValue("max_lwt_f", user_arguments)
    boiler_control = runner.getStringArgumentValue("boiler_control", user_arguments)
    # --- begin user logic ---
    f2c = lambda { |f| (f - 32.0) / 1.8 }
    candidates = unconnected_heat_pumps(model)
    pick = hp_name == FIRST_HP ? candidates.first : candidates.find { |n, _, _| n == hp_name }
    if pick.nil?
      runner.registerError(hp_name == FIRST_HP ? 'The model has no heating heat pump that is not already on a plant loop.' : "Heat pump '#{hp_name}' not found among heat pumps not yet on a plant loop.")
      return false
    end
    hp_name, hp_type, hp = pick
    runner.registerInfo("Heat pump: '#{hp_name}' (#{hp_type}).")
    # An autosized heat pump is sized for the whole loop. It is first in the
    # load-based list, so it is handed the entire load and the boiler never
    # trims above the heat pump's maximum leaving water temperature.
    autosized = { 'HeatPump:PlantLoop:EIR:Heating' => :isReferenceCapacityAutosized,
                  'HeatPump:WaterToWater:EquationFit:Heating' => :isRatedHeatingCapacityAutosized,
                  'HeatPump:AirToWater:FuelFired:Heating' => :isNominalHeatingCapacityAutosized }[hp_type]
    if hp.send(autosized)
      runner.registerWarning("'#{hp_name}' has an autosized capacity, so it will be sized for the whole loop and the boiler will not trim; the loop will not reach its reset temperature above #{max_lwt_f}F. Enter a fixed heat pump capacity.")
    end
    boiler = model.getBoilerHotWaterByName(boiler_name)
    if boiler.empty?
      runner.registerError("Boiler '#{boiler_name}' not found.")
      return false
    end
    boiler = boiler.get
    if boiler.plantLoop.empty?
      runner.registerError("Boiler '#{boiler_name}' is not on a plant loop.")
      return false
    end
    hw = boiler.plantLoop.get
    water_source = hp_type == 'HeatPump:WaterToWater:EquationFit:Heating' ||
                   (hp_type == 'HeatPump:PlantLoop:EIR:Heating' && hp.condenserType == 'WaterSource')
    if water_source && hp.secondaryPlantLoop.empty?
      runner.registerWarning("'#{hp_name}' is water source but its source side is not on a condenser loop; connect it before simulating or EnergyPlus will stop with an error.")
    end

    # The loop OA reset defines the trim setpoint and the heat pump's reset.
    loop_oar = hw.supplyOutletNode.setpointManagers.map { |s| s.to_SetpointManagerOutdoorAirReset }.find(&:is_initialized)
    if loop_oar.nil?
      runner.registerError("'#{hw.name}' has no outdoor air reset setpoint manager on its supply outlet; run Hot Water Supply Outdoor Air Reset first.")
      return false
    end
    loop_oar = loop_oar.get
    runner.registerInitialCondition("'#{hw.name}' supply: #{hw.supplyComponents.reject { |c| c.to_Node.is_initialized }.map { |c| c.name.to_s }.join(' -> ')}.")

    inlet = boiler.inletModelObject.get.to_Node.get
    # Only the EIR heat pump has a Load/Setpoint control field; the others are
    # dispatched by the component setpoint scheme the outlet setpoint creates.
    hp.setControlType('Setpoint') if hp_type == 'HeatPump:PlantLoop:EIR:Heating'
    unless hp.addToNode(inlet)
      runner.registerError("Could not add '#{hp_name}' at '#{inlet.name}'.")
      return false
    end
    hp_out = (hp.respond_to?(:supplyOutletModelObject) ? hp.supplyOutletModelObject : hp.outletModelObject).get.to_Node.get
    boiler_out = boiler.outletModelObject.get.to_Node.get

    # Heat pump setpoint = min(cap, loop reset).
    lo_sp = loop_oar.setpointatOutdoorLowTemperature
    hi_sp = loop_oar.setpointatOutdoorHighTemperature
    lo_oa = loop_oar.outdoorLowTemperature
    hi_oa = loop_oar.outdoorHighTemperature
    cap_c = f2c.call(max_lwt_f)
    hp_spm = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
    hp_spm.setName("#{hp_name} LWT Setpoint")
    if cap_c >= lo_sp
      hp_spm.setSetpointatOutdoorLowTemperature(lo_sp)
      hp_spm.setOutdoorLowTemperature(lo_oa)
    else
      oa_x = lo_oa + (lo_sp - cap_c) / (lo_sp - hi_sp) * (hi_oa - lo_oa)
      hp_spm.setSetpointatOutdoorLowTemperature(cap_c)
      hp_spm.setOutdoorLowTemperature(oa_x)
    end
    hp_spm.setSetpointatOutdoorHighTemperature([hi_sp, cap_c].min)
    hp_spm.setOutdoorHighTemperature(hi_oa)
    hp_spm.addToNode(hp_out)

    if boiler_control == 'Setpoint'
      b_spm = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      b_spm.setName("#{boiler_name} Trim Setpoint")
      b_spm.setSetpointatOutdoorLowTemperature(lo_sp)
      b_spm.setOutdoorLowTemperature(lo_oa)
      b_spm.setSetpointatOutdoorHighTemperature(hi_sp)
      b_spm.setOutdoorHighTemperature(hi_oa)
      b_spm.addToNode(boiler_out)
      boiler.setBoilerFlowMode('LeavingSetpointModulated')
    end
    runner.registerInfo("Boiler trim control: #{boiler_control} (flow mode #{boiler.boilerFlowMode}).")
    runner.registerFinalCondition("'#{hp_name}' is in series ahead of '#{boiler_name}' on '#{hw.name}', leaving water capped at #{max_lwt_f}F; supply: #{hw.supplyComponents.reject { |c| c.to_Node.is_initialized }.map { |c| c.name.to_s }.join(' -> ')}.")
    true
    # --- end user logic ---
    return true
  end
end

AddHeatPumpAheadOfBoiler.new.registerWithApplication
