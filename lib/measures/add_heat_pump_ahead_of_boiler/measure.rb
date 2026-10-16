class AddHeatPumpAheadOfBoiler < OpenStudio::Measure::ModelMeasure
  def name
    return "Add Heat Pump Ahead Of Boiler"
  end

  def description
    return "Connects an existing heating heat pump that is not yet on a plant loop (plant loop EIR, water-to-water equation fit, or fuel-fired air-to-water) in series ahead of a hot water boiler, so the heat pump preheats the return water and the boiler trims to the loop supply temperature. The heat pump's leaving water temperature follows the loop's existing control, an outdoor air reset or a constant or variable schedule, limited to the lower of the heat pump's maximum and the loop's maximum temperature. A heat pump maximum that varies with outdoor or source temperature (as set by the create measures) is applied each timestep. By default the loop keeps at least the heat pump's design flow, with a bypass for flow the coils do not take. The heat pump's maximum is read from the heat pump when the model has one (as set by Create Air-to-Water Heat Pump or Create Water-to-Water Heat Pump), or entered. Use it after a measure that creates the heat pump, such as Create Air-to-Water Heat Pump or Create Water-to-Water Heat Pump (for a water-source heat pump, also connect its source side, for example with Add Horizontal Trench Ground Loop). The loop's supply outlet must have an outdoor air reset or scheduled temperature setpoint manager."
  end

  def modeler_description
    return "Supports HeatPumpPlantLoopEIRHeating, HeatPumpWaterToWaterEquationFitHeating and HeatPumpAirToWaterFuelFiredHeating. HeatPumpAirToWater is not supported: in OpenStudio 3.11 the forward translator crashes when a setpoint manager is on its heating mode's outlet node. Adds the selected heat pump at the boiler's inlet node, so it sits in series on the boiler's branch. The loop is the boiler's plant loop; its supply outlet must have a SetpointManagerOutdoorAirReset or a SetpointManagerScheduled with control variable Temperature. The cap is the lowest of the maximum LWT argument (0 = not used), the heat pump's maximum and the loop's MaximumLoopTemperature. The heat pump's maximum is read only for HeatPumpPlantLoopEIRHeating: its MaximumSupplyWaterTemperatureCurve (any curve, or a one-variable Table:Lookup, interpolated here because OpenStudio cannot evaluate tables), else the x (leaving water) maximum of its capacity curve. When that curve varies and its lowest value is below the fixed limits, the setpoint manager is capped at the curve's highest value and an EMS program (calling point AfterPredictorAfterHVACManagers) sets the heat pump outlet node setpoint each timestep to min(loop supply outlet setpoint, @CurveValue at the sensor Heat Pump Source Side Inlet Temperature, fixed limits). The curve is read at the source inlet temperature: outdoor air for an air source, entering source water for a water source. EnergyPlus 25.2 does not hold the EIR heat pump's outlet to that curve (tested: with a 105F curve and a 113F setpoint the heat pump delivered 113F), so the setpoint cap is what enforces it. An entered maximum above the heat pump's is reduced to it with a warning; with 0 entered and no heat pump maximum (equation fit, fuel-fired) the measure stops with an error. The heat pump outlet gets a setpoint manager of the same kind equal to min(cap, loop setpoint): for an outdoor air reset, an end above the cap moves along the reset line to where it crosses the cap; for a ScheduleConstant, a new ScheduleConstant; for a ScheduleRuleset, a clone (rules and day schedules) with each day schedule value capped. Other schedule types are rejected. With a setpoint manager on its outlet the heat pump is dispatched by PlantEquipmentOperation:ComponentSetpoint (for the EIR heat pump ControlType is also set to Setpoint; the other types have no such field). Boiler trim control Load leaves the boiler in the load-based heating scheme. Setpoint gives the boiler outlet its own setpoint manager matching the loop's (uncapped) and sets the boiler flow mode to LeavingSetpointModulated; EnergyPlus then requests design flow continuously, which raises pump energy. Heat pump water flow Bypass sets the plant loop's MinimumLoopFlowRate to the heat pump's load side design flow, adds a demand branch with only a PipeAdiabatic if the loop has none, raises a hard-sized MaximumLoopFlowRate to that flow, fixes an autosized one at it (with a warning; EnergyPlus caps the loop flow at its maximum), and sets an EIR heat pump's FlowMode to ConstantFlow. The heat pump must be in series with the whole loop flow (as when the boiler is on the supply outlet run); on a parallel branch a warning is given. A water-source heat pump whose source side is not connected to a condenser loop is reported as a warning; an EIR heat pump counts as water source if its CondenserType is WaterSource or its AdditionalProperties has IntendedCondenserType = WaterSource (set by Create Water-to-Water Heat Pump)."
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

  # The heat pump's curve getters return the generic Curve, which has no
  # input limits; cast to the concrete type.
  def concrete_curve(curve)
    %w[CurveQuadratic CurveLinear CurveCubic CurveQuartic CurveExponent
       CurveBiquadratic CurveBicubic CurveQuadraticLinear CurveCubicLinear TableLookup].each do |t|
      next unless curve.respond_to?("to_#{t}")
      c = curve.send("to_#{t}")
      return c.get if c.is_initialized
    end
    curve
  end

  # [x, y] points of a one-variable Table:Lookup (deg C), or nil.
  # OpenStudio cannot evaluate a Table:Lookup, so it is interpolated here
  # (linear between points, constant beyond them).
  def table_points(table)
    ivs = table.independentVariables
    return nil unless ivs.size == 1
    xs = ivs[0].values.to_a
    ys = table.outputValues.to_a
    return nil if xs.empty? || xs.size != ys.size
    xs.zip(ys).sort_by(&:first)
  end

  def table_value(pts, x)
    return pts.first[1] if x <= pts.first[0]
    return pts.last[1] if x >= pts.last[0]
    a, b = pts.each_cons(2).find { |_, q| x <= q[0] }
    a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
  end

  # The heat pump's own maximum leaving water temperature (C) as
  # {lo:, hi:, src:, varies:, curve:}, or nil. EnergyPlus does not hold the
  # outlet to the Maximum Supply Water Temperature Curve, so this measure
  # enforces it through the setpoint. Without that curve, an EIR heat pump's
  # CapFT leaving water limit is used (beyond it EnergyPlus holds capacity and
  # COP at the limit). The other types carry no leaving water limit.
  def heat_pump_maximum(hp, hp_type)
    return nil unless hp_type == 'HeatPump:PlantLoop:EIR:Heating'
    curve = hp.maximumSupplyWaterTemperatureCurve
    if curve.is_initialized
      curve = concrete_curve(curve.get)
      if curve.to_TableLookup.is_initialized
        pts = table_points(curve.to_TableLookup.get)
        return nil if pts.nil?
        values = pts.map(&:last)
      else
        lo = curve.respond_to?(:minimumValueofx) ? curve.minimumValueofx : -50.0
        hi = curve.respond_to?(:maximumValueofx) ? curve.maximumValueofx : 60.0
        values = (0..100).map { |i| curve.evaluate(lo + (hi - lo) * i / 100.0) }
      end
      varies = values.max - values.min > 1e-6
      return { lo: values.min, hi: values.max, varies: varies, curve: curve,
               src: "Maximum Supply Water Temperature Curve '#{curve.name}'" }
    end
    capft = concrete_curve(hp.capacityModifierFunctionofTemperatureCurve)
    if capft.respond_to?(:maximumValueofx)
      return { lo: capft.maximumValueofx, hi: capft.maximumValueofx, varies: false, curve: nil,
               src: "CapFT '#{capft.name}' leaving water limit" }
    end
    nil
  end

  # Heat pump design (load side) flow, m3/s, or nil if autosized or unknown.
  def design_flow(hp, hp_type)
    v = case hp_type
        when 'HeatPump:PlantLoop:EIR:Heating' then hp.loadSideReferenceFlowRate
        when 'HeatPump:WaterToWater:EquationFit:Heating' then hp.referenceLoadSideFlowRate
        else hp.respond_to?(:designFlowRate) ? hp.designFlowRate : nil
        end
    return nil if v.nil?
    v.respond_to?(:is_initialized) ? (v.is_initialized ? v.get : nil) : v
  end

  # Demand branches with nothing but pipes on them.
  def demand_bypass?(loop)
    loop.demandSplitter.outletModelObjects.any? do |o|
      comps = loop.demandComponents(o.to_HVACComponent.get, loop.demandMixer)
      comps.reject { |c| c.to_Node.is_initialized || c.to_ConnectorMixer.is_initialized }.all? { |c| c.to_PipeAdiabatic.is_initialized }
    end
  end

  def ems_name(text)
    text.gsub(/[^A-Za-z0-9]/, '_')
  end

  def c2f_s(c)
    (c * 1.8 + 32.0).round(1)
  end

  # New outdoor air reset equal to min(cap_c, loop reset). An end above the
  # cap moves along the reset line to where it crosses the cap; if both ends
  # are above, the result is the cap at all outdoor temperatures.
  def capped_reset(model, oar, cap_c)
    oa_lo = oar.outdoorLowTemperature
    oa_hi = oar.outdoorHighTemperature
    sp_lo = oar.setpointatOutdoorLowTemperature
    sp_hi = oar.setpointatOutdoorHighTemperature
    if (sp_lo > cap_c) != (sp_hi > cap_c)
      oa_x = oa_lo + (sp_lo - cap_c) / (sp_lo - sp_hi) * (oa_hi - oa_lo)
      sp_lo > cap_c ? oa_lo = oa_x : oa_hi = oa_x
    end
    spm = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
    spm.setOutdoorLowTemperature(oa_lo)
    spm.setOutdoorHighTemperature(oa_hi)
    spm.setSetpointatOutdoorLowTemperature([sp_lo, cap_c].min)
    spm.setSetpointatOutdoorHighTemperature([sp_hi, cap_c].min)
    spm
  end

  # New schedule equal to min(cap_c, sched): a ScheduleConstant stays
  # constant; a ScheduleRuleset is cloned (rules and day schedules) and each
  # day schedule's values are capped.
  def capped_schedule(model, sched, cap_c, name)
    if sched.to_ScheduleConstant.is_initialized
      new_sched = OpenStudio::Model::ScheduleConstant.new(model)
      new_sched.setValue([sched.to_ScheduleConstant.get.value, cap_c].min)
    else
      new_sched = sched.to_ScheduleRuleset.get.clone(model).to_ScheduleRuleset.get
      days = [new_sched.defaultDaySchedule, new_sched.summerDesignDaySchedule, new_sched.winterDesignDaySchedule,
              new_sched.holidaySchedule, new_sched.customDay1Schedule, new_sched.customDay2Schedule] +
             new_sched.scheduleRules.map(&:daySchedule)
      days.uniq { |d| d.handle.to_s }.each do |day|
        times = day.times
        values = day.values
        day.clearValues
        times.each_with_index { |t, i| day.addValue(t, [values[i], cap_c].min) }
      end
    end
    new_sched.setName(name)
    limits = sched.scheduleTypeLimits
    new_sched.setScheduleTypeLimits(limits.get) if limits.is_initialized
    new_sched
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
    max_lwt_f.setDescription("Cap on the heat pump's leaving water setpoint, deg F. 0 uses the heat pump's own maximum: its Maximum Supply Water Temperature Curve (set by Create Air-to-Water Heat Pump and Create Water-to-Water Heat Pump), or for a plant loop EIR heat pump without one, its capacity curve's leaving water limit. A value above the heat pump's maximum is reduced to it, and the loop's maximum temperature applies if it is lower still. Water-to-water equation fit and fuel-fired heat pumps carry no maximum in the model, so enter one for them. Above the cap the boiler supplies the rest of the loop's setpoint.")
    max_lwt_f.setDefaultValue(0.0)
    args << max_lwt_f
    boiler_control_choices = OpenStudio::StringVector.new
    boiler_control_choices << "Load"
    boiler_control_choices << "Setpoint"
    boiler_control = OpenStudio::Measure::OSArgument.makeChoiceArgument("boiler_control", boiler_control_choices, boiler_control_choices, true)
    boiler_control.setDisplayName("Boiler trim control")
    boiler_control.setDescription("Load: the boiler stays in the load-based heating scheme and its flow follows coil demand. Setpoint: the boiler gets its own setpoint manager matching the loop's (component setpoint scheme); EnergyPlus then requests design flow continuously, which raises pump energy.")
    boiler_control.setDefaultValue("Load")
    args << boiler_control
    hp_flow_choices = OpenStudio::StringVector.new
    hp_flow_choices << "Bypass"
    hp_flow_choices << "Loop flow"
    hp_flow = OpenStudio::Measure::OSArgument.makeChoiceArgument("hp_flow", hp_flow_choices, hp_flow_choices, true)
    hp_flow.setDisplayName("Heat pump water flow")
    hp_flow.setDescription("Bypass: the loop keeps at least the heat pump's design flow, with the excess returning through a demand-side bypass pipe (added if the loop has none), so the heat pump always sees its design flow. Loop flow: the heat pump sees whatever the coils draw, which can fall below the manufacturer's minimum.")
    hp_flow.setDefaultValue("Bypass")
    args << hp_flow
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
    hp_flow = runner.getStringArgumentValue("hp_flow", user_arguments)
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
      runner.registerWarning("'#{hp_name}' has an autosized capacity, so it will be sized for the whole loop and the boiler will not trim; the loop will not reach its setpoint above the heat pump's maximum leaving water temperature. Enter a fixed heat pump capacity.")
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
    # An EIR heat pump shows AirSource until its source side is on a loop;
    # Create Water-to-Water Heat Pump tags the intended type.
    tag = hp.additionalProperties.getFeatureAsString('IntendedCondenserType')
    water_source = hp_type == 'HeatPump:WaterToWater:EquationFit:Heating' ||
                   (hp_type == 'HeatPump:PlantLoop:EIR:Heating' &&
                    (hp.condenserType == 'WaterSource' || (tag.is_initialized && tag.get == 'WaterSource')))
    if water_source && hp.secondaryPlantLoop.empty?
      runner.registerWarning("'#{hp_name}' is water source but its source side is not on a condenser loop; connect it before simulating or EnergyPlus will stop with an error.")
    end

    # The heat pump's setpoint follows the loop's own temperature control: an
    # outdoor air reset or a schedule.
    loop_spm = nil
    hw.supplyOutletNode.setpointManagers.each do |s|
      oar = s.to_SetpointManagerOutdoorAirReset
      sch = s.to_SetpointManagerScheduled
      loop_spm = oar.get if oar.is_initialized && oar.get.controlVariable == 'Temperature'
      loop_spm = sch.get if sch.is_initialized && sch.get.controlVariable == 'Temperature'
      break if loop_spm
    end
    if loop_spm.nil?
      found = hw.supplyOutletNode.setpointManagers.map { |s| "#{s.name} (#{s.iddObjectType.valueDescription})" }
      runner.registerError("'#{hw.name}' supply outlet has no outdoor air reset or scheduled temperature setpoint manager#{found.empty? ? '' : " (found: #{found.join(', ')})"}; the heat pump setpoint is built from one of those.")
      return false
    end
    loop_sched = nil
    if loop_spm.to_SetpointManagerScheduled.is_initialized
      loop_sched = loop_spm.schedule
      if loop_sched.to_ScheduleConstant.empty? && loop_sched.to_ScheduleRuleset.empty?
        runner.registerError("'#{loop_spm.name}' uses '#{loop_sched.name}' (#{loop_sched.iddObjectType.valueDescription}); only constant and ruleset schedules can be capped for the heat pump.")
        return false
      end
    end
    # Cap: the lowest of the entered maximum, the heat pump's own maximum and
    # the loop maximum.
    if max_lwt_f < 0
      runner.registerError('Maximum heat pump leaving water temperature must be 0 (use the heat pump maximum) or a temperature in deg F.')
      return false
    end
    hp_max = heat_pump_maximum(hp, hp_type)
    # Fixed limits always apply. A heat pump maximum that varies is applied
    # each timestep by an EMS program; the setpoint manager is capped at its
    # highest value.
    limits = []
    if max_lwt_f > 0
      limits << [f2c.call(max_lwt_f), 'the entered maximum']
      if hp_max && f2c.call(max_lwt_f) > hp_max[:hi] + 1e-6
        runner.registerWarning("The entered maximum leaving water temperature (#{max_lwt_f}F) is above '#{hp_name}' maximum of #{c2f_s(hp_max[:hi])}F (#{hp_max[:src]}); #{c2f_s(hp_max[:hi])}F is used.")
      end
    elsif hp_max.nil?
      runner.registerError("'#{hp_name}' (#{hp_type}) has no maximum leaving water temperature in the model; enter one for Maximum heat pump leaving water temperature.")
      return false
    end
    limits << [hw.maximumLoopTemperature, "'#{hw.name}' maximum loop temperature"]
    fixed_c, fixed_src = limits.min_by(&:first)
    use_ems = hp_max && hp_max[:varies] && hp_max[:lo] < fixed_c - 1e-6
    if hp_max
      limits << [use_ems ? hp_max[:hi] : hp_max[:lo], "'#{hp_name}' maximum (#{hp_max[:src]}#{use_ems ? ', highest value' : ''})"]
    end
    cap_c, cap_src = limits.min_by(&:first)
    cap_f = cap_c * 1.8 + 32.0
    if use_ems
      runner.registerInfo("Heat pump leaving water cap: #{c2f_s(hp_max[:lo])}F to #{cap_f.round(1)}F, following #{hp_max[:src]} each timestep (EMS), and never above #{c2f_s(fixed_c)}F (#{fixed_src}).")
    else
      runner.registerInfo("Heat pump leaving water cap: #{cap_f.round(1)}F, from #{cap_src}.")
    end
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

    # Heat pump setpoint = min(cap, loop setpoint), of the same kind as the loop's.
    if loop_sched.nil?
      hp_spm = capped_reset(model, loop_spm, cap_c)
      runner.registerInfo("'#{hp_name}' setpoint: outdoor air reset #{c2f_s(hp_spm.setpointatOutdoorLowTemperature)}F at #{c2f_s(hp_spm.outdoorLowTemperature)}F OA to #{c2f_s(hp_spm.setpointatOutdoorHighTemperature)}F at #{c2f_s(hp_spm.outdoorHighTemperature)}F OA (loop reset capped at #{cap_f.round(1)}F).")
    else
      hp_sched = capped_schedule(model, loop_sched, cap_c, "#{hp_name} LWT Setpoint Schedule")
      hp_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, hp_sched)
      kind = hp_sched.to_ScheduleConstant.is_initialized ? "constant #{c2f_s(hp_sched.to_ScheduleConstant.get.value)}F" : "ruleset schedule '#{hp_sched.name}'"
      runner.registerInfo("'#{hp_name}' setpoint: #{kind} (loop schedule '#{loop_sched.name}' capped at #{cap_f.round(1)}F).")
    end
    hp_spm.setControlVariable('Temperature')
    hp_spm.setName("#{hp_name} LWT Setpoint")
    hp_spm.addToNode(hp_out)

    if use_ems
      # Each timestep: heat pump setpoint = min(loop setpoint, heat pump
      # maximum at its source inlet temperature, fixed cap). The maximum curve
      # is read at the source inlet temperature: the outdoor air for an air
      # source, the entering source water for a water source.
      tag_n = ems_name(hp_name)
      s_src = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Heat Pump Source Side Inlet Temperature')
      s_src.setName("#{tag_n}_Source_T")
      s_src.setKeyName(hp_name)
      s_sp = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Setpoint Temperature')
      s_sp.setName("#{tag_n}_Loop_SP")
      s_sp.setKeyName(hw.supplyOutletNode.name.to_s)
      idx = OpenStudio::Model::EnergyManagementSystemCurveOrTableIndexVariable.new(model, hp_max[:curve])
      idx.setName("#{tag_n}_Max_Curve")
      act = OpenStudio::Model::EnergyManagementSystemActuator.new(hp_out, 'System Node Setpoint', 'Temperature Setpoint')
      act.setName("#{tag_n}_SP")
      prog = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      prog.setName("#{tag_n}_Max_LWT")
      ["SET mx = @CurveValue #{idx.name} #{s_src.name}",
       "SET sp = #{s_sp.name}",
       'IF sp > mx',
       'SET sp = mx',
       'ENDIF',
       "IF sp > #{format('%.4f', fixed_c)}",
       "SET sp = #{format('%.4f', fixed_c)}",
       'ENDIF',
       "SET #{act.name} = sp"].each { |line| prog.addLine(line) }
      pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      pcm.setName("#{tag_n}_Max_LWT_Manager")
      pcm.setCallingPoint('AfterPredictorAfterHVACManagers')
      pcm.addProgram(prog)
      runner.registerInfo("EMS program '#{prog.name}' sets '#{hp_out.name}' setpoint each timestep to the lowest of the loop setpoint, '#{hp_max[:curve].name}' at the heat pump's source inlet temperature, and #{c2f_s(fixed_c)}F.")
    end

    if hp_flow == 'Bypass'
      flow = design_flow(hp, hp_type)
      if flow.nil?
        runner.registerWarning("'#{hp_name}' design flow is autosized or unknown, so the loop's minimum flow was not set; the heat pump sees the loop flow.")
      else
        gpm = (flow / 6.30902e-5).round(1)
        unless demand_bypass?(hw)
          pipe = OpenStudio::Model::PipeAdiabatic.new(model)
          pipe.setName("#{hw.name} Minimum Flow Bypass")
          hw.addDemandBranchForComponent(pipe)
          runner.registerInfo("Added demand bypass pipe '#{pipe.name}' to '#{hw.name}'.")
        end
        hw.setMinimumLoopFlowRate(flow) if hw.minimumLoopFlowRate.empty? || hw.minimumLoopFlowRate.get < flow
        if hw.isMaximumLoopFlowRateAutosized
          hw.setMaximumLoopFlowRate(flow)
          runner.registerWarning("'#{hw.name}' maximum flow was autosized; it is now fixed at the heat pump's design flow, #{gpm} gpm, so the loop can hold that flow (EnergyPlus caps the loop at its maximum). If the coils need more, enter a larger maximum.")
        elsif hw.maximumLoopFlowRate.get < flow
          hw.setMaximumLoopFlowRate(flow)
          runner.registerInfo("'#{hw.name}' maximum flow raised to the heat pump's design flow, #{gpm} gpm.")
        end
        # An autosized pump is sized from the plant sizing flow, not the loop
        # maximum, so it can still hold the loop below the heat pump flow.
        hw.supplyComponents.each do |c|
          pump = c.to_PumpVariableSpeed.is_initialized ? c.to_PumpVariableSpeed.get : (c.to_PumpConstantSpeed.is_initialized ? c.to_PumpConstantSpeed.get : nil)
          next if pump.nil?
          if pump.isRatedFlowRateAutosized
            pump.setRatedFlowRate(hw.maximumLoopFlowRate.get)
            runner.registerWarning("'#{pump.name}' rated flow was autosized; it is now fixed at #{(hw.maximumLoopFlowRate.get / 6.30902e-5).round(1)} gpm, the loop maximum, so it can deliver the heat pump's design flow. Its power is still autosized from that flow and its head.")
          elsif pump.ratedFlowRate.get < flow
            pump.setRatedFlowRate(flow)
            runner.registerInfo("'#{pump.name}' rated flow raised to the heat pump's design flow, #{gpm} gpm.")
          end
        end
        hp.setFlowMode('ConstantFlow') if hp.respond_to?(:setFlowMode)
        # Parallel supply branches that hold equipment share the loop flow; a
        # pipe-only supply bypass takes flow only when the equipment is off.
        branches = hw.supplySplitter.outletModelObjects.map do |o|
          hw.supplyComponents(o.to_HVACComponent.get, hw.supplyMixer).reject { |c| c.to_Node.is_initialized || c.to_ConnectorMixer.is_initialized }
        end
        hp_branch = branches.find { |b| b.any? { |c| c.handle.to_s == hp.handle.to_s } }
        if hp_branch && (branches - [hp_branch]).any? { |b| b.any? { |c| c.to_PipeAdiabatic.empty? } }
          runner.registerWarning("'#{hp_name}' is on a supply branch in parallel with other equipment, so the loop's minimum flow is shared among branches and does not guarantee the heat pump's design flow.")
        end
        runner.registerInfo("Heat pump flow: '#{hw.name}' minimum flow set to #{gpm} gpm, the heat pump's design flow; flow the coils do not take returns through the demand bypass.")
      end
    end

    if boiler_control == 'Setpoint'
      # The boiler trims to the loop's own setpoint, uncapped.
      if loop_sched.nil?
        b_spm = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
        b_spm.setSetpointatOutdoorLowTemperature(loop_spm.setpointatOutdoorLowTemperature)
        b_spm.setOutdoorLowTemperature(loop_spm.outdoorLowTemperature)
        b_spm.setSetpointatOutdoorHighTemperature(loop_spm.setpointatOutdoorHighTemperature)
        b_spm.setOutdoorHighTemperature(loop_spm.outdoorHighTemperature)
      else
        b_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, loop_sched)
      end
      b_spm.setControlVariable('Temperature')
      b_spm.setName("#{boiler_name} Trim Setpoint")
      b_spm.addToNode(boiler_out)
      boiler.setBoilerFlowMode('LeavingSetpointModulated')
    end
    runner.registerInfo("Boiler trim control: #{boiler_control} (flow mode #{boiler.boilerFlowMode}).")
    runner.registerFinalCondition("'#{hp_name}' is in series ahead of '#{boiler_name}' on '#{hw.name}', leaving water capped at #{cap_f.round(1)}F; supply: #{hw.supplyComponents.reject { |c| c.to_Node.is_initialized }.map { |c| c.name.to_s }.join(' -> ')}.")
    true
    # --- end user logic ---
    return true
  end
end

AddHeatPumpAheadOfBoiler.new.registerWithApplication
