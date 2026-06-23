require 'openstudio'

class VAVTerminalUnoccupiedSetback < OpenStudio::Measure::ModelMeasure

  DAY_METHODS = [
    [:sunday,    :applySunday,    :setApplySunday],
    [:monday,    :applyMonday,    :setApplyMonday],
    [:tuesday,   :applyTuesday,   :setApplyTuesday],
    [:wednesday, :applyWednesday, :setApplyWednesday],
    [:thursday,  :applyThursday,  :setApplyThursday],
    [:friday,    :applyFriday,    :setApplyFriday],
    [:saturday,  :applySaturday,  :setApplySaturday],
  ].freeze

  TERMINAL_CAST_METHODS = [
    :to_AirTerminalSingleDuctVAVReheat,
    :to_AirTerminalSingleDuctVAVHeatAndCoolReheat,
    :to_AirTerminalSingleDuctVAVNoReheat,
    :to_AirTerminalSingleDuctVAVHeatAndCoolNoReheat,
    :to_AirTerminalDualDuctVAV,
    :to_AirTerminalDualDuctVAVOutdoorAir,
  ].freeze

  def name
    "VAV Terminal Unoccupied Setback"
  end

  def description
    "For a selected thermal zone, applies unoccupied setbacks: " \
    "(1) derives the occupancy schedule via Space → Space Type → People, creates " \
    "a modified airflow turndown schedule, and assigns it to the zone's VAV terminal; " \
    "(2) finds the zone thermostat DualSetpoint, clones the heating and cooling setpoint " \
    "temperature schedules with setback temperatures substituted during unoccupied periods; " \
    "(3) finds the zone ZoneControlHumidistat, clones the humidifying and dehumidifying " \
    "setpoint schedules with setback humidity values substituted during unoccupied periods. " \
    "Setting a setback value to 0 skips that setback entirely. " \
    "The measure can be used to model ASHRAE 170 healthcare setbacks."
  end

  def modeler_description
    "OpenStudio Measure: Occupancy is resolved from Space (in zone) → SpaceType → People → Number of People Schedule. " \
    "The turndown schedule (ScheduleRuleset) is cloned from the occupancy schedule with occupied " \
    "values (> 0.1) → 1.0 and unoccupied values → turndown_fraction. Temperature and humidity " \
    "setback schedules are cloned from the existing setpoint schedules; each day profile is merged " \
    "with the corresponding occupancy day profile so that unoccupied periods (occ ≤ 0.1) receive " \
    "the user-specified setback value. Rules are matched by index (rule[i] of temp schedule " \
    "paired with rule[i] of occupancy schedule); falls back to the occupancy default day if the " \
    "occupancy schedule has fewer rules. New schedules are named " \
    "'<zone>_Minimum Air Flow Turndown Schedule' and '<zone>_<sched>_Setback'. Setting any " \
    "setback argument to 0 skips creation of that schedule. Humidity setback requires " \
    "ZoneControlHumidistat. Supports AirTerminalSingleDuctVAVReheat, VAVHeatAndCoolReheat, " \
    "VAVNoReheat, VAVHeatAndCoolNoReheat, AirTerminalDualDuctVAV, and " \
    "AirTerminalDualDuctVAVOutdoorAir. " \
    "Warning: The measure will overwrite design day schedules. If equipment is autosized, " \
    "this may resize equipment capacities. If this measure is being run on existing equipment " \
    "it is recommended to hardsize the equipment first. Implementing setbacks on existing " \
    "equipment not originally sized for setback may encounter shortages in capacity."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    zone_names = model.getThermalZones.map { |z| z.name.get }.sort
    zone_vec = OpenStudio::StringVector.new
    zone_names.each { |n| zone_vec << n }
    zone_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument("zone_name", zone_vec, true)
    zone_arg.setDisplayName("Thermal Zone")
    zone_arg.setDescription(
      "Select the thermal zone to apply unoccupied setbacks. The zone must have a Space " \
      "with a Space Type, a People object referencing that Space Type with a Number of People " \
      "Schedule, a supported VAV terminal on an air loop, and a ZoneControl:Thermostat (for " \
      "temperature setbacks) or ZoneControl:Humidistat (for humidity setbacks)."
    )
    args << zone_arg

    frac_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("turndown_fraction", true)
    frac_arg.setDisplayName("Minimum Air Flow Turndown Fraction (0-1)")
    frac_arg.setDescription(
      "The minimum fraction of design airflow supplied to the zone during unoccupied periods. " \
      "Occupied periods are set to 1.0. A value of 0.25 means the VAV terminal delivers 25% " \
      "of design flow when unoccupied."
    )
    frac_arg.setDefaultValue(0.25)
    args << frac_arg

    thresh_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("occ_threshold", true)
    thresh_arg.setDisplayName("Unoccupied Sensitivity Threshold (0-1)")
    thresh_arg.setDescription(
      "Occupancy schedule value at or below which a period is considered unoccupied and " \
      "setback values are applied. The default of 0.1 means any occupancy fraction ≤ 10% " \
      "is treated as unoccupied. Must be ≥ 0 and < 1."
    )
    thresh_arg.setDefaultValue(0.1)
    args << thresh_arg

    htg_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("heating_setback_temp", true)
    htg_arg.setDisplayName("Heating Setback Temperature {C} (0=No Setback)")
    htg_arg.setDescription(
      "Heating setpoint temperature in degrees Celsius applied during unoccupied periods. " \
      "The existing heating setpoint schedule is cloned and unoccupied periods are replaced " \
      "with this value. Set to 0 to skip heating setpoint modification."
    )
    htg_arg.setDefaultValue(0)
    args << htg_arg

    clg_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("cooling_setback_temp", true)
    clg_arg.setDisplayName("Cooling Setback Temperature {C} (0=No Setback)")
    clg_arg.setDescription(
      "Cooling setpoint temperature in degrees Celsius applied during unoccupied periods. " \
      "The existing cooling setpoint schedule is cloned and unoccupied periods are replaced " \
      "with this value. Set to 0 to skip cooling setpoint modification."
    )
    clg_arg.setDefaultValue(0)
    args << clg_arg

    hum_high_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("humidity_high_setback", true)
    hum_high_arg.setDisplayName("Dehumidifying Setback {% RH} (0=No Setback)")
    hum_high_arg.setDescription(
      "Dehumidifying relative humidity setpoint (% RH) applied during unoccupied periods. " \
      "The existing dehumidifying setpoint schedule is cloned and unoccupied periods are " \
      "replaced with this value. Set to 0 to skip dehumidifying setpoint modification."
    )
    hum_high_arg.setDefaultValue(0)
    args << hum_high_arg

    hum_low_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("humidity_low_setback", true)
    hum_low_arg.setDisplayName("Humidifying Setback {% RH} (0=No Setback)")
    hum_low_arg.setDescription(
      "Humidifying relative humidity setpoint (% RH) applied during unoccupied periods. " \
      "The existing humidifying setpoint schedule is cloned and unoccupied periods are " \
      "replaced with this value. Set to 0 to skip humidifying setpoint modification."
    )
    hum_low_arg.setDefaultValue(0)
    args << hum_low_arg

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    zone_name              = runner.getStringArgumentValue("zone_name", user_arguments)
    turndown_fraction      = runner.getDoubleArgumentValue("turndown_fraction", user_arguments)
    @occ_threshold         = runner.getDoubleArgumentValue("occ_threshold", user_arguments)
    heating_setback_temp   = runner.getDoubleArgumentValue("heating_setback_temp", user_arguments)
    cooling_setback_temp   = runner.getDoubleArgumentValue("cooling_setback_temp", user_arguments)
    humidity_high_setback  = runner.getDoubleArgumentValue("humidity_high_setback", user_arguments)
    humidity_low_setback   = runner.getDoubleArgumentValue("humidity_low_setback", user_arguments)

    apply_htg_setback      = heating_setback_temp != 0
    apply_clg_setback      = cooling_setback_temp != 0
    apply_hum_high_setback = humidity_high_setback != 0
    apply_hum_low_setback  = humidity_low_setback != 0

    if turndown_fraction < 0.0 || turndown_fraction > 1.0
      runner.registerError("Turndown fraction must be between 0 and 1; got #{turndown_fraction}.")
      return false
    end

    if @occ_threshold < 0.0 || @occ_threshold >= 1.0
      runner.registerError("Occupancy threshold must be >= 0 and < 1; got #{@occ_threshold}.")
      return false
    end

    runner.registerInitialCondition(
      "Applying VAV terminal unoccupied setback to zone '#{zone_name}': " \
      "turndown=#{turndown_fraction}, htg_setback=#{heating_setback_temp}C, " \
      "clg_setback=#{cooling_setback_temp}C."
    )

    # ── Find ThermalZone ──────────────────────────────────────────────────────
    thermal_zone = model.getThermalZones.find { |z| z.name.get == zone_name }
    unless thermal_zone
      runner.registerError("Thermal zone '#{zone_name}' not found.")
      return false
    end

    # ── Find Space → SpaceType → People → occupancy schedule ─────────────────
    occ_sched       = nil
    space_type_name = nil

    thermal_zone.spaces.each do |space|
      st_opt = space.spaceType
      next unless st_opt.is_initialized
      st = st_opt.get
      space_type_name = st.name.get
      st.people.each do |ppl|
        s_opt = ppl.numberofPeopleSchedule
        if s_opt.is_initialized
          occ_sched = s_opt.get
          break
        end
      end
      break if occ_sched
    end

    unless occ_sched
      runner.registerError(
        "No occupancy schedule found via Space → SpaceType → People for zone '#{zone_name}'."
      )
      return false
    end
    runner.registerInfo("Space Type: '#{space_type_name}'. Occupancy schedule: '#{occ_sched.name.get}'")

    occ_ruleset_opt = occ_sched.to_ScheduleRuleset
    unless occ_ruleset_opt.is_initialized
      runner.registerError(
        "Occupancy schedule '#{occ_sched.name.get}' is not a ScheduleRuleset; " \
        "cannot create setback schedules."
      )
      return false
    end
    occ_ruleset = occ_ruleset_opt.get

    # ── Create airflow turndown schedule ──────────────────────────────────────
    airflow_sched_name = "#{zone_name}_Minimum Air Flow Turndown Schedule"
    airflow_sched = clone_and_transform_ruleset(model, occ_ruleset, airflow_sched_name) do |v|
      v > @occ_threshold ? 1.0 : turndown_fraction
    end
    runner.registerInfo("Created airflow turndown schedule '#{airflow_sched_name}'.")

    # ── Find VAV terminal and assign turndown schedule ────────────────────────
    terminal = find_vav_terminal_for_zone(model, thermal_zone, runner)
    unless terminal
      runner.registerError("No supported VAV terminal found for zone '#{zone_name}'.")
      return false
    end
    terminal_type = terminal.iddObjectType.valueName
    runner.registerInfo("VAV terminal: #{terminal_type} '#{terminal.name.get}'")

    unless set_terminal_turndown_schedule(terminal, airflow_sched, runner)
      return false
    end
    runner.registerInfo("Assigned airflow turndown schedule to terminal.")

    # ── Temperature setbacks ──────────────────────────────────────────────────
    new_htg_sched_name = nil
    new_clg_sched_name = nil

    if apply_htg_setback || apply_clg_setback
      thermostat_opt = thermal_zone.thermostatSetpointDualSetpoint
      unless thermostat_opt.is_initialized
        runner.registerError("No ThermostatSetpointDualSetpoint found for zone '#{zone_name}'.")
        return false
      end
      thermostat = thermostat_opt.get

      if apply_htg_setback
        htg_sched_opt = thermostat.heatingSetpointTemperatureSchedule
        if htg_sched_opt.is_initialized
          htg_sched = htg_sched_opt.get
          htg_rs_opt = htg_sched.to_ScheduleRuleset
          if htg_rs_opt.is_initialized
            new_htg_sched_name = "#{zone_name}_#{htg_sched.name.get}_Setback"
            new_htg_sched = clone_and_apply_setback(
              model, htg_rs_opt.get, occ_ruleset, new_htg_sched_name, heating_setback_temp
            )
            thermostat.setHeatingSetpointTemperatureSchedule(new_htg_sched)
            runner.registerInfo("Created heating setback schedule '#{new_htg_sched_name}'.")
          else
            runner.registerWarning(
              "Heating setpoint schedule '#{htg_sched.name.get}' is not a ScheduleRuleset; skipping."
            )
          end
        else
          runner.registerWarning("No heating setpoint schedule on thermostat; skipping.")
        end
      else
        runner.registerInfo("Heating setback is 0; skipping heating setpoint modification.")
      end

      if apply_clg_setback
        clg_sched_opt = thermostat.coolingSetpointTemperatureSchedule
        if clg_sched_opt.is_initialized
          clg_sched = clg_sched_opt.get
          clg_rs_opt = clg_sched.to_ScheduleRuleset
          if clg_rs_opt.is_initialized
            new_clg_sched_name = "#{zone_name}_#{clg_sched.name.get}_Setback"
            new_clg_sched = clone_and_apply_setback(
              model, clg_rs_opt.get, occ_ruleset, new_clg_sched_name, cooling_setback_temp
            )
            thermostat.setCoolingSetpointTemperatureSchedule(new_clg_sched)
            runner.registerInfo("Created cooling setback schedule '#{new_clg_sched_name}'.")
          else
            runner.registerWarning(
              "Cooling setpoint schedule '#{clg_sched.name.get}' is not a ScheduleRuleset; skipping."
            )
          end
        else
          runner.registerWarning("No cooling setpoint schedule on thermostat; skipping.")
        end
      else
        runner.registerInfo("Cooling setback is 0; skipping cooling setpoint modification.")
      end
    end

    # ── Humidity setbacks ─────────────────────────────────────────────────────
    new_hum_low_sched_name  = nil
    new_hum_high_sched_name = nil

    if apply_hum_high_setback || apply_hum_low_setback
      humidistat_opt = thermal_zone.zoneControlHumidistat
      unless humidistat_opt.is_initialized
        runner.registerError("No ZoneControlHumidistat found for zone '#{zone_name}'.")
        return false
      end
      humidistat = humidistat_opt.get

      if apply_hum_low_setback
        hum_sched_opt = humidistat.humidifyingRelativeHumiditySetpointSchedule
        if hum_sched_opt.is_initialized
          hum_sched = hum_sched_opt.get
          hum_rs_opt = hum_sched.to_ScheduleRuleset
          if hum_rs_opt.is_initialized
            new_hum_low_sched_name = "#{zone_name}_#{hum_sched.name.get}_Setback"
            new_hum_low_sched = clone_and_apply_setback(
              model, hum_rs_opt.get, occ_ruleset, new_hum_low_sched_name, humidity_low_setback
            )
            humidistat.setHumidifyingRelativeHumiditySetpointSchedule(new_hum_low_sched)
            runner.registerInfo("Created humidifying setback schedule '#{new_hum_low_sched_name}'.")
          else
            runner.registerWarning(
              "Humidifying setpoint schedule '#{hum_sched.name.get}' is not a ScheduleRuleset; skipping."
            )
          end
        else
          runner.registerWarning("No humidifying setpoint schedule on humidistat; skipping.")
        end
      else
        runner.registerInfo("Humidity low setback is 0; skipping humidifying setpoint modification.")
      end

      if apply_hum_high_setback
        dehum_sched_opt = humidistat.dehumidifyingRelativeHumiditySetpointSchedule
        if dehum_sched_opt.is_initialized
          dehum_sched = dehum_sched_opt.get
          dehum_rs_opt = dehum_sched.to_ScheduleRuleset
          if dehum_rs_opt.is_initialized
            new_hum_high_sched_name = "#{zone_name}_#{dehum_sched.name.get}_Setback"
            new_hum_high_sched = clone_and_apply_setback(
              model, dehum_rs_opt.get, occ_ruleset, new_hum_high_sched_name, humidity_high_setback
            )
            humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(new_hum_high_sched)
            runner.registerInfo("Created dehumidifying setback schedule '#{new_hum_high_sched_name}'.")
          else
            runner.registerWarning(
              "Dehumidifying setpoint schedule '#{dehum_sched.name.get}' is not a ScheduleRuleset; skipping."
            )
          end
        else
          runner.registerWarning("No dehumidifying setpoint schedule on humidistat; skipping.")
        end
      else
        runner.registerInfo("Humidity high setback is 0; skipping dehumidifying setpoint modification.")
      end
    end

    runner.registerFinalCondition(
      "Zone '#{zone_name}': assigned airflow turndown '#{airflow_sched_name}' to " \
      "#{terminal_type} '#{terminal.name.get}'; " \
      "heating setpoint → '#{new_htg_sched_name || "(not modified)"}'; " \
      "cooling setpoint → '#{new_clg_sched_name || "(not modified)"}'; " \
      "humidifying setpoint → '#{new_hum_low_sched_name || "(not modified)"}'; " \
      "dehumidifying setpoint → '#{new_hum_high_sched_name || "(not modified)"}'."
    )
    true
  end

  private

  # Clones a ScheduleRuleset and transforms every value using the given block.
  def clone_and_transform_ruleset(model, source, new_name, &transform)
    new_sched = source.clone(model).to_ScheduleRuleset.get
    new_sched.setName(new_name)

    profiles = [new_sched.defaultDaySchedule]
    profiles << new_sched.summerDesignDaySchedule unless new_sched.isSummerDesignDayScheduleDefaulted
    profiles << new_sched.winterDesignDaySchedule unless new_sched.isWinterDesignDayScheduleDefaulted
    new_sched.scheduleRules.each { |r| profiles << r.daySchedule }

    profiles.each do |day_sch|
      times  = day_sch.times
      values = day_sch.values
      day_sch.clearValues
      times.each_with_index { |t, i| day_sch.addValue(t, transform.call(values[i])) }
    end

    new_sched
  end

  # Builds a setback ScheduleRuleset from scratch.
  # For each rule in occ_ruleset its covered day types are grouped by which temp schedule
  # day applies to them (via effective_temp_day lookup). One setback rule is created per
  # group so that Monday and Tuesday-Friday can correctly reference different temp days when
  # the temp schedule has day-specific rules. Rules are added in reverse occ priority order
  # so the final priority ranking matches the original occ schedule.
  def clone_and_apply_setback(model, temp_ruleset, occ_ruleset, new_name, setback_val)
    new_sched = OpenStudio::Model::ScheduleRuleset.new(model)
    new_sched.setName(new_name)
    new_sched.setScheduleTypeLimits(temp_ruleset.scheduleTypeLimits.get) if temp_ruleset.scheduleTypeLimits.is_initialized

    build_setback_day(new_sched.defaultDaySchedule,
                      temp_ruleset.defaultDaySchedule,
                      occ_ruleset.defaultDaySchedule,
                      setback_val)

    unless temp_ruleset.isSummerDesignDayScheduleDefaulted
      summer_dd = OpenStudio::Model::ScheduleDay.new(model)
      summer_dd.setScheduleTypeLimits(new_sched.scheduleTypeLimits.get) if new_sched.scheduleTypeLimits.is_initialized
      build_setback_day(summer_dd,
                        temp_ruleset.summerDesignDaySchedule,
                        occ_ruleset.summerDesignDaySchedule,
                        setback_val)
      new_sched.setSummerDesignDaySchedule(summer_dd)
    end

    unless temp_ruleset.isWinterDesignDayScheduleDefaulted
      winter_dd = OpenStudio::Model::ScheduleDay.new(model)
      winter_dd.setScheduleTypeLimits(new_sched.scheduleTypeLimits.get) if new_sched.scheduleTypeLimits.is_initialized
      build_setback_day(winter_dd,
                        temp_ruleset.winterDesignDaySchedule,
                        occ_ruleset.winterDesignDaySchedule,
                        setback_val)
      new_sched.setWinterDesignDaySchedule(winter_dd)
    end

    # Process occ rules in reverse so that earlier (higher-priority) rules end up at
    # lower rule indices after all inserts (each ScheduleRule.new pushes to index 0).
    occ_ruleset.scheduleRules.reverse_each do |occ_rule|
      days = DAY_METHODS.select { |_dow, apply, _set| occ_rule.send(apply) }.map { |dow, _, _| dow }
      next if days.empty?

      # Group covered days by which temp schedule day applies to each.
      groups = {}
      days.each do |dow|
        td  = effective_temp_day(temp_ruleset, dow)
        key = td.handle.to_s
        groups[key] ||= { temp_day: td, days: [] }
        groups[key][:days] << dow
      end

      groups.each_value do |grp|
        new_rule = OpenStudio::Model::ScheduleRule.new(new_sched)
        grp[:days].each do |dow|
          setter = DAY_METHODS.find { |d, _, _| d == dow }[2]
          new_rule.send(setter, true)
        end
        new_rule.setStartDate(occ_rule.startDate.get) if occ_rule.startDate.is_initialized
        new_rule.setEndDate(occ_rule.endDate.get) if occ_rule.endDate.is_initialized
        build_setback_day(new_rule.daySchedule, grp[:temp_day], occ_rule.daySchedule, setback_val)
      end
    end

    new_sched
  end

  # Returns the highest-priority temp rule's day schedule that covers day_of_week.
  # Falls back to the temp schedule's default day when no rule applies.
  def effective_temp_day(temp_ruleset, day_of_week)
    apply_method = DAY_METHODS.find { |dow, _, _| dow == day_of_week }[1]
    temp_ruleset.scheduleRules.each do |rule|
      return rule.daySchedule if rule.send(apply_method)
    end
    temp_ruleset.defaultDaySchedule
  end

  # Writes merged setback values into target_day.
  # occ > 0.1 → temp_day value; occ ≤ 0.1 → setback_val.
  def build_setback_day(target_day, temp_day, occ_day, setback_val)
    temp_times = temp_day.times
    temp_vals  = temp_day.values
    occ_times  = occ_day.times
    occ_vals   = occ_day.values

    all_minutes = (temp_times.map { |t| t.totalMinutes } +
                   occ_times.map  { |t| t.totalMinutes }).uniq.sort

    target_day.clearValues
    prev_mins = 0.0

    all_minutes.each do |t_mins|
      query_mins = (prev_mins + t_mins) / 2.0
      occ_val    = lookup_value_at_mins(occ_times, occ_vals, query_mins)
      temp_val   = lookup_value_at_mins(temp_times, temp_vals, query_mins)
      final_val  = occ_val <= @occ_threshold ? setback_val.to_f : temp_val
      target_day.addValue(
        OpenStudio::Time.new(0, t_mins.to_i / 60, t_mins.to_i % 60, 0),
        final_val
      )
      prev_mins = t_mins
    end
  end

  # Looks up the value that applies at query_mins in a ScheduleDay's (times, values).
  def lookup_value_at_mins(os_times, values, query_mins)
    os_times.each_with_index do |t, i|
      return values[i] if query_mins <= t.totalMinutes
    end
    values.last || 0.0
  end

  # Finds the first supported VAV terminal on the air loop branch serving thermal_zone.
  def find_vav_terminal_for_zone(model, thermal_zone, runner)
    unless thermal_zone.airLoopHVAC.is_initialized
      runner.registerError("Zone '#{thermal_zone.name.get}' is not connected to an air loop.")
      return nil
    end
    air_loop = thermal_zone.airLoopHVAC.get

    branch_comps = air_loop.demandComponents(air_loop.zoneSplitter, thermal_zone)

    branch_comps.each do |comp|
      TERMINAL_CAST_METHODS.each do |cast|
        opt = comp.send(cast) rescue nil
        return opt.get if opt&.is_initialized
      end
    end

    nil
  end

  # Sets the minimum airflow turndown schedule on the terminal; non-fatal if unsupported.
  def set_terminal_turndown_schedule(terminal, schedule, runner)
    if terminal.respond_to?(:setMinimumAirFlowTurndownSchedule)
      terminal.setMinimumAirFlowTurndownSchedule(schedule)
      return true
    end
    runner.registerWarning(
      "#{terminal.iddObjectType.valueName} does not support " \
      "setMinimumAirFlowTurndownSchedule; airflow turndown schedule not assigned."
    )
    true
  end
end

VAVTerminalUnoccupiedSetback.new.registerWithApplication
