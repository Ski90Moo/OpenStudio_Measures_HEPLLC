class DisableChilledWaterCooling < OpenStudio::Measure::ModelMeasure
  def name
    return "Disable Chilled Water Cooling"
  end

  def description
    return "Turns off a chilled water cooling system for the annual simulation without removing any components. An on/off availability schedule is applied to the chilled water plant loop and to every chilled water cooling coil it serves. The schedule is off all year but can be left on for the summer design day so that equipment sizing still runs. Useful for buildings whose chilled water system is not yet installed or is out of service, while keeping the model ready for when cooling is added."
  end

  def modeler_description
    return "Finds the selected PlantLoop and reuses the ScheduleRuleset with the given name or creates one: default day 0, winter design day 0, summer design day 1 (or 0 if cooling is off for the summer design day too), using an OnOff Discrete/Availability ScheduleTypeLimits. If the loop already has an AvailabilityManagerScheduledOff, it is pointed at the schedule. Otherwise a new one is added at priority 1, ahead of any existing availability managers. A schedule value of 0 forces the loop off. Every CoilCoolingWater whose plantLoop is this loop gets the schedule as its availability schedule. This includes cooling coils inside zone equipment such as fan coils. The parent equipment's own availability schedule is not changed, because it also runs the fan and the heating. Other demand components, such as cooled beams, radiant cooling or fluid-to-fluid heat exchangers, are listed in a warning but not changed. Nothing is removed, and sizing objects are not changed."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # Choices are the model's plant loops. Default: the first loop serving a
    # chilled water coil, else the first loop sized as a Cooling loop.
    loops = model.getPlantLoops
    loop_names = OpenStudio::StringVector.new
    loops.each { |l| loop_names << l.name.to_s }
    chw_loop_name = OpenStudio::Measure::OSArgument.makeChoiceArgument("chw_loop_name", loop_names, true)
    chw_loop_name.setDisplayName("Chilled water plant loop")
    chw_loop_name.setDescription("Chilled water PlantLoop to turn off, chosen from the plant loops in the model.")
    coil_loops = model.getCoilCoolingWaters.map { |c| c.plantLoop }.select(&:is_initialized).map { |l| l.get.name.to_s }
    default_loop = loops.find { |l| coil_loops.include?(l.name.to_s) } ||
                   loops.find { |l| l.sizingPlant.loopType.to_s.casecmp('Cooling').zero? }
    chw_loop_name.setDefaultValue(default_loop.name.to_s) if default_loop
    args << chw_loop_name
    schedule_name = OpenStudio::Measure::OSArgument.makeStringArgument("schedule_name", true)
    schedule_name.setDisplayName("Off schedule name")
    schedule_name.setDescription("Name of the on/off ScheduleRuleset to apply. If a ruleset with this name already exists it is reused as-is; otherwise it is created (off all year, on for the summer design day if selected below).")
    schedule_name.setDefaultValue("Chilled Water Off")
    args << schedule_name
    on_for_summer_design_day = OpenStudio::Measure::OSArgument.makeBoolArgument("on_for_summer_design_day", true)
    on_for_summer_design_day.setDisplayName("Keep cooling available on the summer design day")
    on_for_summer_design_day.setDescription("When true, the new schedule is 1 on the summer design day so design-day sizing simulations still exercise cooling. Ignored when an existing schedule is reused.")
    on_for_summer_design_day.setDefaultValue(true)
    args << on_for_summer_design_day
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    chw_loop_name = runner.getStringArgumentValue("chw_loop_name", user_arguments)
    schedule_name = runner.getStringArgumentValue("schedule_name", user_arguments)
    on_for_summer_design_day = runner.getBoolArgumentValue("on_for_summer_design_day", user_arguments)
    # --- begin user logic ---
    # --- Find the chilled water loop ---
    loop = model.getPlantLoopByName(chw_loop_name)
    if loop.empty?
      runner.registerError("Plant loop '#{chw_loop_name}' not found.")
      return false
    end
    loop = loop.get
    coils = model.getCoilCoolingWaters.select { |c| c.plantLoop.is_initialized && c.plantLoop.get.handle == loop.handle }
    runner.registerInitialCondition("Plant loop '#{loop.name}' serves #{coils.size} chilled water cooling coils.")

    # --- Off schedule: reuse by name or create ---
    sch = model.getScheduleRulesetByName(schedule_name)
    if sch.is_initialized
      sch = sch.get
      runner.registerInfo("Reusing existing schedule '#{sch.name}'.")
    else
      limits = model.getScheduleTypeLimitss.find do |l|
        l.lowerLimitValue.is_initialized && l.lowerLimitValue.get == 0.0 &&
          l.upperLimitValue.is_initialized && l.upperLimitValue.get == 1.0 &&
          l.numericType.to_s.casecmp('Discrete').zero?
      end
      if limits.nil?
        limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
        limits.setName('OnOff')
        limits.setLowerLimitValue(0.0)
        limits.setUpperLimitValue(1.0)
        limits.setNumericType('Discrete')
        limits.setUnitType('Availability')
      end
      sch = OpenStudio::Model::ScheduleRuleset.new(model, 0.0)
      sch.setName(schedule_name)
      sch.setScheduleTypeLimits(limits)
      sch.defaultDaySchedule.setName("#{schedule_name} Default Off")
      [['Summer', on_for_summer_design_day ? 1.0 : 0.0], ['Winter', 0.0]].each do |season, value|
        day = OpenStudio::Model::ScheduleDay.new(model, value)
        if season == 'Summer'
          sch.setSummerDesignDaySchedule(day)
          set_day = sch.summerDesignDaySchedule
        else
          sch.setWinterDesignDaySchedule(day)
          set_day = sch.winterDesignDaySchedule
        end
        day.remove if set_day.handle != day.handle
        set_day.setName("#{schedule_name} #{season} Design Day #{value > 0 ? 'On' : 'Off'}")
        set_day.setScheduleTypeLimits(limits)
      end
      runner.registerInfo("Created schedule '#{sch.name}': off all year, #{on_for_summer_design_day ? 'on' : 'off'} on the summer design day.")
    end

    # --- Plant loop availability ---
    avms = loop.availabilityManagers
    avm = avms.map { |a| a.to_AvailabilityManagerScheduledOff }.find(&:is_initialized)
    if avm
      avm = avm.get
      avm.setSchedule(sch)
      runner.registerInfo("Set schedule of existing availability manager '#{avm.name}' to '#{sch.name}'.")
    else
      avm = OpenStudio::Model::AvailabilityManagerScheduledOff.new(model)
      avm.setName("#{loop.name} Scheduled Off")
      avm.setSchedule(sch)
      loop.addAvailabilityManager(avm)
      loop.setAvailabilityManagerPriority(avm, 1)
      runner.registerInfo("Added availability manager '#{avm.name}' to '#{loop.name}' at priority 1.")
    end
    others = loop.availabilityManagers.reject { |a| a.handle == avm.handle }
    unless others.empty?
      runner.registerWarning("'#{loop.name}' also has availability managers #{others.map { |a| "'#{a.name}'" }.join(', ')}. Confirm they cannot turn the loop back on.")
    end

    # --- Cooling coil availability ---
    coils.each do |c|
      old = c.availabilitySchedule.name.to_s
      c.setAvailabilitySchedule(sch)
      runner.registerInfo("Coil '#{c.name}': availability '#{old}' -> '#{sch.name}'.")
    end

    # --- Report other demand components left unchanged ---
    skip = ['OS:Node', 'OS:Connector:Splitter', 'OS:Connector:Mixer', 'OS:Pipe:Adiabatic', 'OS:Coil:Cooling:Water']
    other = loop.demandComponents.reject { |c| skip.include?(c.iddObjectType.valueDescription) }
    unless other.empty?
      runner.registerWarning("Demand components not given the off schedule (check them by hand): #{other.map { |c| "#{c.name} (#{c.iddObjectType.valueDescription})" }.join('; ')}.")
    end

    runner.registerFinalCondition("'#{loop.name}' and #{coils.size} chilled water coils now follow '#{sch.name}'. No components were removed.")
    true
    # --- end user logic ---
    return true
  end
end

DisableChilledWaterCooling.new.registerWithApplication
