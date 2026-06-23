class VAVTerminalUnoccupiedSetbackEnergyPlus < OpenStudio::Measure::EnergyPlusMeasure

  # Minimum Air Flow Turndown Schedule Name field index (0-based) per terminal type.
  # Indices verified against EnergyPlus 24.2 IDD.
  TERMINAL_FIELD_INDEX = {
    "AirTerminal:SingleDuct:VAV:Reheat"                  => 20,
    "AirTerminal:SingleDuct:VAV:Reheat:VariableSpeedFan" => 20,
    "AirTerminal:SingleDuct:VAV:HeatAndCool:Reheat"      => 13,
    "AirTerminal:SingleDuct:VAV:NoReheat"                => 10,
    "AirTerminal:SingleDuct:VAV:HeatAndCool:NoReheat"    => 6,
  }.freeze

  def name
    return "VAV Terminal Unoccupied Setback EnergyPlus"
  end

  def description
    return "For a selected thermal zone, applies unoccupied setbacks: " \
           "(1) derives the occupancy schedule via Space → Space Type → People, creates " \
           "a modified airflow turndown schedule, and assigns it to the zone's VAV terminal; " \
           "(2) finds the zone thermostat DualSetpoint, copies the heating and cooling setpoint " \
           "temperature schedules with setback temperatures substituted during unoccupied periods; " \
           "(3) finds the zone ZoneControl:Humidistat, copies the humidifying and dehumidifying " \
           "setpoint schedules with setback humidity values substituted during unoccupied periods. " \
           "Setting a setback value to 0 skips that setback entirely. " \
           "The measure can be used to model ASHRAE 170 healthcare setbacks."
  end

  def modeler_description
    return "EnergyPlus Measure: Occupancy is resolved from Space (Zone Name) → SpaceType → People → Number of " \
           "People Schedule Name. The turndown schedule (Schedule:Year or Schedule:Compact) " \
           "is copied with occupied values → 1.0 and unoccupied values → turndown_fraction. " \
           "Temperature and humidity setback copies are built by merging the occupancy " \
           "day-interval breakpoints into each setpoint Schedule:Day:Interval; unoccupied " \
           "periods (occ ≤ 0.1) receive the user-specified setback value. Different day types " \
           "in the week schedule receive distinct copies so each day type's occupancy pattern " \
           "is correctly reflected. New schedules are named '<zone>_Minimum Air Flow Turndown " \
           "Schedule', '<zone>_<sched>_Setback'. Setting any setback argument to 0 skips " \
           "creation of that schedule. Humidity setback requires ZoneControl:Humidistat. " \
           "Warning: The measure will overwrite design day schedules. If equipment is autosized, " \
           "this may resize equipment capacities. If this measure is being run on existing equipment " \
           "it is recommended to hardsize the equipment first. Implementing setbacks on existing " \
           "equipment not originally sized for setback may encounter shortages in capacity."
  end

  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    zone_names_arr = []
    workspace.getObjectsByType("Zone".to_IddObjectType).each do |z|
      opt = z.getString(0)
      zone_names_arr << opt.get if opt.is_initialized
    end
    zone_names_arr.sort!
    zone_vec = OpenStudio::StringVector.new
    zone_names_arr.each { |n| zone_vec << n }
    zone_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument("zone_name", zone_vec, true)
    zone_arg.setDisplayName("Thermal Zone")
    zone_arg.setDescription("Select the thermal zone to apply ASHRAE 170 unoccupied setbacks. The zone must have a Space with a Space Type, a People object referencing that Space Type, a VAV terminal, and a ZoneControl:Thermostat (for temperature setbacks) or ZoneControl:Humidistat (for humidity setbacks).")
    args << zone_arg

    frac_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("turndown_fraction", true)
    frac_arg.setDisplayName("Minimum Air Flow Turndown Fraction (0-1)")
    frac_arg.setDescription("The minimum fraction of design airflow supplied to the zone during unoccupied periods. Occupied periods are set to 1.0. A value of 0.25 means the VAV terminal delivers 25% of design flow when unoccupied.")
    frac_arg.setDefaultValue(0.25)
    args << frac_arg

    thresh_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("occ_threshold", true)
    thresh_arg.setDisplayName("Unoccupied Sensitivity Threshold (0-1)")
    thresh_arg.setDescription("Occupancy schedule value at or below which a period is considered unoccupied and setback values are applied. The default of 0.1 means any occupancy fraction ≤ 10% is treated as unoccupied. Must be ≥ 0 and < 1.")
    thresh_arg.setDefaultValue(0.1)
    args << thresh_arg

    htg_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("heating_setback_temp", true)
    htg_arg.setDisplayName("Heating Setback Temperature {C} (0=No Setback)")
    htg_arg.setDescription("Heating setpoint temperature in degrees Celsius applied during unoccupied periods. The existing heating setpoint schedule is copied and unoccupied periods are replaced with this value. Set to 0 to skip heating setpoint modification.")
    htg_arg.setDefaultValue(0)
    args << htg_arg

    clg_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("cooling_setback_temp", true)
    clg_arg.setDisplayName("Cooling Setback Temperature {C} (0=No Setback)")
    clg_arg.setDescription("Cooling setpoint temperature in degrees Celsius applied during unoccupied periods. The existing cooling setpoint schedule is copied and unoccupied periods are replaced with this value. Set to 0 to skip cooling setpoint modification.")
    clg_arg.setDefaultValue(0)
    args << clg_arg

    hum_high_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("humidity_high_setback", true)
    hum_high_arg.setDisplayName("Dehumidifying Setback {% RH} (0=No Setback)")
    hum_high_arg.setDescription("Dehumidifying relative humidity setpoint (% RH) applied during unoccupied periods. The existing dehumidifying setpoint schedule is copied and unoccupied periods are replaced with this value. Set to 0 to skip dehumidifying setpoint modification.")
    hum_high_arg.setDefaultValue(0)
    args << hum_high_arg

    hum_low_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument("humidity_low_setback", true)
    hum_low_arg.setDisplayName("Humidifying Setback {% RH} (0=No Setback)")
    hum_low_arg.setDescription("Humidifying relative humidity setpoint (% RH) applied during unoccupied periods. The existing humidifying setpoint schedule is copied and unoccupied periods are replaced with this value. Set to 0 to skip humidifying setpoint modification.")
    hum_low_arg.setDefaultValue(0)
    args << hum_low_arg

    args
  end

  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    zone_name            = runner.getStringArgumentValue("zone_name", user_arguments)
    turndown_fraction    = runner.getDoubleArgumentValue("turndown_fraction", user_arguments)
    @occ_threshold       = runner.getDoubleArgumentValue("occ_threshold", user_arguments)
    heating_setback_temp = runner.getDoubleArgumentValue("heating_setback_temp", user_arguments)
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
      "Applying ASHRAE 170 unoccupied setback to zone '#{zone_name}': " \
      "turndown=#{turndown_fraction}, htg_setback=#{heating_setback_temp}C, " \
      "clg_setback=#{cooling_setback_temp}C."
    )

    # ── Find Space → Space Type ───────────────────────────────────────────────
    # Space: 0=Name, 1=Zone Name, 2=Ceiling Height, 3=Volume, 4=Floor Area, 5=Space Type
    space_type_name = nil
    workspace.getObjectsByType("Space".to_IddObjectType).each do |sp|
      zn_f = sp.getString(1)
      next unless zn_f.is_initialized && zn_f.get.casecmp(zone_name) == 0
      st_f = sp.getString(5)
      space_type_name = st_f.get if st_f.is_initialized && !st_f.get.empty?
      break
    end

    unless space_type_name
      runner.registerError("No Space found for zone '#{zone_name}', or Space Type is blank.")
      return false
    end
    runner.registerInfo("Space Type: '#{space_type_name}'")

    # ── Find People → occupancy schedule ─────────────────────────────────────
    # People: 0=Name, 1=Zone/ZoneList/Space/SpaceList Name, 2=Number of People Schedule Name
    occ_sched_name = nil
    workspace.getObjectsByType("People".to_IddObjectType).each do |ppl|
      ref_f = ppl.getString(1)
      next unless ref_f.is_initialized && ref_f.get.casecmp(space_type_name) == 0
      sch_f = ppl.getString(2)
      occ_sched_name = sch_f.get if sch_f.is_initialized && !sch_f.get.empty?
      break
    end

    unless occ_sched_name
      runner.registerError("No People object found with Space/SpaceType name '#{space_type_name}'.")
      return false
    end
    runner.registerInfo("Occupancy schedule: '#{occ_sched_name}'")

    # Locate the top-level occupancy schedule object (needed for temperature setback correlation)
    occ_year_obj    = find_by_name(workspace, "Schedule:Year",    occ_sched_name)
    occ_compact_obj = find_by_name(workspace, "Schedule:Compact", occ_sched_name)

    # ── Create airflow turndown schedule ──────────────────────────────────────
    airflow_sched_name = "#{zone_name}_Minimum Air Flow Turndown Schedule"

    if occ_year_obj
      return false unless copy_schedule_year_turndown(
        workspace, runner, occ_year_obj, occ_sched_name, airflow_sched_name, turndown_fraction
      )
    elsif occ_compact_obj
      return false unless copy_schedule_compact_turndown(
        workspace, runner, occ_compact_obj, airflow_sched_name, turndown_fraction
      )
    else
      runner.registerError(
        "Occupancy schedule '#{occ_sched_name}' not found as Schedule:Year or Schedule:Compact."
      )
      return false
    end
    runner.registerInfo("Created airflow turndown schedule '#{airflow_sched_name}'.")

    # ── Find ZoneHVAC:EquipmentConnections → EquipmentList → VAV terminal ─────
    equip_list_name = nil
    workspace.getObjectsByType("ZoneHVAC:EquipmentConnections".to_IddObjectType).each do |conn|
      zn = conn.getString(0)
      next unless zn.is_initialized && zn.get.casecmp(zone_name) == 0
      el = conn.getString(1)
      equip_list_name = el.get if el.is_initialized
      break
    end

    unless equip_list_name
      runner.registerError("No ZoneHVAC:EquipmentConnections found for zone '#{zone_name}'.")
      return false
    end

    equip_list_obj = workspace.getObjectsByType("ZoneHVAC:EquipmentList".to_IddObjectType).find do |el|
      n = el.getString(0)
      n.is_initialized && n.get.casecmp(equip_list_name) == 0
    end

    unless equip_list_obj
      runner.registerError("ZoneHVAC:EquipmentList '#{equip_list_name}' not found.")
      return false
    end

    terminal_type = nil
    terminal_name = nil
    num_fields = equip_list_obj.numFields

    (0...num_fields - 1).each do |i|
      fv = equip_list_obj.getString(i)
      next unless fv.is_initialized
      fv_str = fv.get.to_s.strip

      if fv_str.casecmp("ZoneHVAC:AirDistributionUnit") == 0
        adu_name_f = equip_list_obj.getString(i + 1)
        next unless adu_name_f.is_initialized && !adu_name_f.get.empty?
        adu_obj = workspace.getObjectsByType("ZoneHVAC:AirDistributionUnit".to_IddObjectType).find do |a|
          n = a.getString(0)
          n.is_initialized && n.get.casecmp(adu_name_f.get) == 0
        end
        next unless adu_obj
        tt_f = adu_obj.getString(2)
        tn_f = adu_obj.getString(3)
        next unless tt_f.is_initialized && tn_f.is_initialized
        tt_str = tt_f.get.to_s.strip
        next unless TERMINAL_FIELD_INDEX.key?(tt_str)
        terminal_type = tt_str
        terminal_name = tn_f.get
        break
      end

      TERMINAL_FIELD_INDEX.each_key do |tt|
        next unless fv_str.casecmp(tt) == 0
        nf = equip_list_obj.getString(i + 1)
        next unless nf.is_initialized && !nf.get.empty?
        terminal_type = tt
        terminal_name = nf.get
        break
      end
      break if terminal_type
    end

    unless terminal_type
      runner.registerError("No supported VAV terminal found in equipment list '#{equip_list_name}'.")
      return false
    end
    runner.registerInfo("VAV terminal: #{terminal_type} '#{terminal_name}'")

    terminal_obj = begin
      workspace.getObjectsByType(terminal_type.to_IddObjectType).find do |t|
        n = t.getString(0)
        n.is_initialized && n.get.casecmp(terminal_name) == 0
      end
    rescue StandardError
      nil
    end

    unless terminal_obj
      runner.registerError("#{terminal_type} '#{terminal_name}' not found.")
      return false
    end

    field_index = TERMINAL_FIELD_INDEX[terminal_type]
    unless terminal_obj.setString(field_index, airflow_sched_name)
      runner.registerError("setString failed for '#{terminal_name}' at field #{field_index}.")
      return false
    end
    runner.registerInfo("Assigned airflow turndown schedule to terminal.")

    new_htg_sched_name = nil
    new_clg_sched_name = nil

    if apply_htg_setback || apply_clg_setback

    # ── Find ZoneControl:Thermostat → ThermostatSetpoint:DualSetpoint ─────────
    # ZoneControl:Thermostat: 0=Name, 1=Zone Name, 2=CtrlTypeSched,
    #                         3=Control1ObjectType, 4=Control1Name
    dual_sp_name = nil
    workspace.getObjectsByType("ZoneControl:Thermostat".to_IddObjectType).each do |tc|
      zn_f = tc.getString(1)
      next unless zn_f.is_initialized && zn_f.get.casecmp(zone_name) == 0
      cn_f = tc.getString(4)
      dual_sp_name = cn_f.get if cn_f.is_initialized && !cn_f.get.empty?
      break
    end

    unless dual_sp_name
      runner.registerError("No ZoneControl:Thermostat found for zone '#{zone_name}'.")
      return false
    end
    runner.registerInfo("Thermostat control: '#{dual_sp_name}'")

    # ThermostatSetpoint:DualSetpoint: 0=Name, 1=HtgSchedName, 2=ClgSchedName
    dual_sp_obj = find_by_name(workspace, "ThermostatSetpoint:DualSetpoint", dual_sp_name)
    unless dual_sp_obj
      runner.registerError("ThermostatSetpoint:DualSetpoint '#{dual_sp_name}' not found.")
      return false
    end

    htg_sched_f = dual_sp_obj.getString(1)
    clg_sched_f = dual_sp_obj.getString(2)

    unless htg_sched_f.is_initialized && !htg_sched_f.get.empty?
      runner.registerError("Heating setpoint schedule name is blank in '#{dual_sp_name}'.")
      return false
    end
    unless clg_sched_f.is_initialized && !clg_sched_f.get.empty?
      runner.registerError("Cooling setpoint schedule name is blank in '#{dual_sp_name}'.")
      return false
    end

    htg_sched_name = htg_sched_f.get
    clg_sched_name = clg_sched_f.get
    runner.registerInfo("Heating setpoint schedule: '#{htg_sched_name}'")
    runner.registerInfo("Cooling setpoint schedule: '#{clg_sched_name}'")

    # ── Create heating setback schedule ───────────────────────────────────────
    new_htg_sched_name = htg_sched_name
    if apply_htg_setback
      new_htg_sched_name = "#{zone_name}_#{htg_sched_name}_Setback"
      htg_year_obj = find_by_name(workspace, "Schedule:Year", htg_sched_name)

      if htg_year_obj && occ_year_obj
        return false unless copy_schedule_year_setback(
          workspace, runner, htg_year_obj, occ_year_obj,
          htg_sched_name, new_htg_sched_name, heating_setback_temp
        )
      elsif htg_year_obj
        runner.registerWarning(
          "Occupancy schedule '#{occ_sched_name}' is not Schedule:Year; " \
          "heating setback cannot be correlated. No heating setback applied."
        )
        new_htg_sched_name = htg_sched_name
      else
        runner.registerWarning(
          "Heating setpoint schedule '#{htg_sched_name}' is not Schedule:Year; " \
          "only Schedule:Year is supported. No heating setback applied."
        )
        new_htg_sched_name = htg_sched_name
      end
    else
      runner.registerInfo("Heating setback temperature is 0; skipping heating setpoint schedule modification.")
    end

    # ── Create cooling setback schedule ───────────────────────────────────────
    new_clg_sched_name = clg_sched_name
    if apply_clg_setback
      new_clg_sched_name = "#{zone_name}_#{clg_sched_name}_Setback"
      clg_year_obj = find_by_name(workspace, "Schedule:Year", clg_sched_name)

      if clg_year_obj && occ_year_obj
        return false unless copy_schedule_year_setback(
          workspace, runner, clg_year_obj, occ_year_obj,
          clg_sched_name, new_clg_sched_name, cooling_setback_temp
        )
      elsif clg_year_obj
        runner.registerWarning(
          "Occupancy schedule '#{occ_sched_name}' is not Schedule:Year; " \
          "cooling setback cannot be correlated. No cooling setback applied."
        )
        new_clg_sched_name = clg_sched_name
      else
        runner.registerWarning(
          "Cooling setpoint schedule '#{clg_sched_name}' is not Schedule:Year; " \
          "only Schedule:Year is supported. No cooling setback applied."
        )
        new_clg_sched_name = clg_sched_name
      end
    else
      runner.registerInfo("Cooling setback temperature is 0; skipping cooling setpoint schedule modification.")
    end

    # ── Assign new setpoint schedules to DualSetpoint ─────────────────────────
    unless dual_sp_obj.setString(1, new_htg_sched_name)
      runner.registerError("Failed to set heating setpoint schedule on '#{dual_sp_name}'.")
      return false
    end
    unless dual_sp_obj.setString(2, new_clg_sched_name)
      runner.registerError("Failed to set cooling setpoint schedule on '#{dual_sp_name}'.")
      return false
    end

    end # if apply_htg_setback || apply_clg_setback

    new_hum_low_sched_name  = nil
    new_hum_high_sched_name = nil

    if apply_hum_high_setback || apply_hum_low_setback

    # ── Find ZoneControl:Humidistat ───────────────────────────────────────────
    # ZoneControl:Humidistat: 0=Name, 1=Zone Name, 2=HumidifyingSched, 3=DehumidifyingSched
    humidistat_obj = workspace.getObjectsByType("ZoneControl:Humidistat".to_IddObjectType).find do |hc|
      zn_f = hc.getString(1)
      zn_f.is_initialized && zn_f.get.casecmp(zone_name) == 0
    end

    unless humidistat_obj
      runner.registerError("No ZoneControl:Humidistat found for zone '#{zone_name}'.")
      return false
    end
    runner.registerInfo("Found humidistat '#{humidistat_obj.getString(0).get}'.")

    # ── Create humidifying (low limit) setback schedule: field 2 ─────────────
    hum_sched_f    = humidistat_obj.getString(2)
    hum_sched_name = (hum_sched_f.is_initialized && !hum_sched_f.get.empty?) ? hum_sched_f.get : nil

    if apply_hum_low_setback
      if hum_sched_name
        new_hum_low_sched_name = "#{zone_name}_#{hum_sched_name}_Setback"
        hum_year_obj = find_by_name(workspace, "Schedule:Year", hum_sched_name)
        if hum_year_obj && occ_year_obj
          return false unless copy_schedule_year_setback(
            workspace, runner, hum_year_obj, occ_year_obj,
            hum_sched_name, new_hum_low_sched_name, humidity_low_setback
          )
        else
          runner.registerWarning(
            "Humidifying setpoint schedule '#{hum_sched_name}' is not Schedule:Year; " \
            "only Schedule:Year is supported. No humidity low setback applied."
          )
          new_hum_low_sched_name = hum_sched_name
        end
        unless humidistat_obj.setString(2, new_hum_low_sched_name)
          runner.registerError("Failed to set humidifying setpoint schedule on humidistat.")
          return false
        end
      else
        runner.registerWarning("Humidifying setpoint schedule field is blank in humidistat; cannot apply humidity low setback.")
      end
    else
      runner.registerInfo("Humidity low setback is 0; skipping humidifying schedule modification.")
    end

    # ── Create dehumidifying (high limit) setback schedule: field 3 ───────────
    dehum_sched_f    = humidistat_obj.getString(3)
    dehum_sched_name = (dehum_sched_f.is_initialized && !dehum_sched_f.get.empty?) ? dehum_sched_f.get : nil

    if apply_hum_high_setback
      if dehum_sched_name
        new_hum_high_sched_name = "#{zone_name}_#{dehum_sched_name}_Setback"
        dehum_year_obj = find_by_name(workspace, "Schedule:Year", dehum_sched_name)
        if dehum_year_obj && occ_year_obj
          return false unless copy_schedule_year_setback(
            workspace, runner, dehum_year_obj, occ_year_obj,
            dehum_sched_name, new_hum_high_sched_name, humidity_high_setback
          )
        else
          runner.registerWarning(
            "Dehumidifying setpoint schedule '#{dehum_sched_name}' is not Schedule:Year; " \
            "only Schedule:Year is supported. No humidity high setback applied."
          )
          new_hum_high_sched_name = dehum_sched_name
        end
        unless humidistat_obj.setString(3, new_hum_high_sched_name)
          runner.registerError("Failed to set dehumidifying setpoint schedule on humidistat.")
          return false
        end
      else
        runner.registerWarning("Dehumidifying setpoint schedule field is blank in humidistat; cannot apply humidity high setback.")
      end
    else
      runner.registerInfo("Humidity high setback is 0; skipping dehumidifying schedule modification.")
    end

    end # if apply_hum_high_setback || apply_hum_low_setback

    runner.registerFinalCondition(
      "Zone '#{zone_name}': assigned airflow turndown '#{airflow_sched_name}' to " \
      "#{terminal_type} '#{terminal_name}'; heating setpoint → '#{new_htg_sched_name || "(not modified)"}'; " \
      "cooling setpoint → '#{new_clg_sched_name || "(not modified)"}'; " \
      "humidifying setpoint → '#{new_hum_low_sched_name || "(not modified)"}'; " \
      "dehumidifying setpoint → '#{new_hum_high_sched_name || "(not modified)"}'."
    )
    true
  end

  private

  # ── Shared schedule helpers ───────────────────────────────────────────────────

  def find_by_name(workspace, idd_type, name)
    workspace.getObjectsByType(idd_type.to_IddObjectType).find do |obj|
      n = obj.getString(0)
      n.is_initialized && n.get.casecmp(name) == 0
    end
  rescue StandardError
    nil
  end

  def fields_of(obj)
    (0...obj.numFields).map do |i|
      f = obj.getString(i)
      f.is_initialized ? f.get.to_s : ""
    end
  end

  def add_idf_object(workspace, idd_type, fields)
    lines = ["#{idd_type},"]
    fields.each_with_index do |f, i|
      sep = (i == fields.size - 1) ? ";" : ","
      lines << "  #{f}#{sep}"
    end
    parsed = OpenStudio::IdfObject.load(lines.join("\n"))
    return false if parsed.empty?
    workspace.addObject(parsed.get)
    true
  end

  # Converts "HH:MM" to total minutes. Returns nil if not a valid time string.
  def time_to_minutes(time_str)
    m = time_str.to_s.strip.match(/\A(\d+):(\d+)\z/)
    return nil unless m
    m[1].to_i * 60 + m[2].to_i
  end

  # Formats total minutes back to "H:MM" (supports 24:00).
  def minutes_to_time(mins)
    h = mins / 60
    m = mins % 60
    format("%02d:%02d", h, m)
  end

  # ── Airflow turndown: copy occupancy schedule with 0→fraction, 1→1.0 ────────

  def apply_turndown(val_str, fraction)
    num = Float(val_str.to_s.strip)
    num > @occ_threshold ? "1.0" : fraction.to_s
  rescue ArgumentError, TypeError
    val_str
  end

  def copy_day_interval_turndown(workspace, runner, orig_name, new_name, fraction, processed)
    return processed[orig_name] if processed.key?(orig_name)

    day_obj = find_by_name(workspace, "Schedule:Day:Interval", orig_name)
    unless day_obj
      runner.registerWarning("Schedule:Day:Interval '#{orig_name}' not found; keeping reference.")
      processed[orig_name] = orig_name
      return orig_name
    end

    flds    = fields_of(day_obj)
    flds[0] = new_name

    # Value fields at indices 4, 6, 8, ... (time fields at 3, 5, 7, ...)
    i = 4
    while i < flds.size
      flds[i] = apply_turndown(flds[i], fraction)
      i += 2
    end

    add_idf_object(workspace, "Schedule:Day:Interval", flds)
    processed[orig_name] = new_name
    new_name
  end

  def copy_schedule_year_turndown(workspace, runner, year_obj, orig_name, new_name, fraction)
    year_fields = fields_of(year_obj)
    week_names  = []
    i = 2
    while i < year_fields.size
      wn = year_fields[i].strip
      week_names << wn if !wn.empty? && !week_names.include?(wn)
      i += 5
    end

    day_processed = {}
    week_name_map = {}

    week_names.each do |wn|
      wk_obj = find_by_name(workspace, "Schedule:Week:Daily", wn)
      unless wk_obj
        runner.registerWarning("Schedule:Week:Daily '#{wn}' not found; skipping.")
        next
      end

      new_wn    = derive_new_name(wn, orig_name, new_name)
      wk_fields = fields_of(wk_obj)
      wk_fields[0] = new_wn

      (1...wk_fields.size).each do |fi|
        orig_dn = wk_fields[fi]
        next if orig_dn.strip.empty?
        new_dn = derive_new_name(orig_dn, orig_name, new_name)
        wk_fields[fi] = copy_day_interval_turndown(
          workspace, runner, orig_dn, new_dn, fraction, day_processed
        )
      end

      unless add_idf_object(workspace, "Schedule:Week:Daily", wk_fields)
        runner.registerError("Failed to create Schedule:Week:Daily '#{new_wn}'.")
        return false
      end
      week_name_map[wn] = new_wn
    end

    new_year_fields    = year_fields.dup
    new_year_fields[0] = new_name
    i = 2
    while i < new_year_fields.size
      wn = new_year_fields[i]
      new_year_fields[i] = week_name_map[wn] if week_name_map.key?(wn)
      i += 5
    end

    unless add_idf_object(workspace, "Schedule:Year", new_year_fields)
      runner.registerError("Failed to create Schedule:Year '#{new_name}'.")
      return false
    end
    true
  end

  def copy_schedule_compact_turndown(workspace, runner, compact_obj, new_name, fraction)
    flds    = fields_of(compact_obj)
    flds[0] = new_name

    (2...flds.size).each do |i|
      next if flds[i].strip =~ /\A(Through:|For:|Until:)/i
      flds[i] = apply_turndown(flds[i], fraction)
    end

    unless add_idf_object(workspace, "Schedule:Compact", flds)
      runner.registerError("Failed to create Schedule:Compact '#{new_name}'.")
      return false
    end
    true
  end

  # ── Temperature setback: copy setpoint schedule with setback during unoccupied ──

  # Parses a Schedule:Day:Interval field array into [(minutes, value_str), ...].
  # Fields layout: 0=Name, 1=TypeLimits, 2=Interpolate, 3=Time1, 4=Val1, 5=Time2, 6=Val2, ...
  def parse_day_interval(flds)
    points = []
    i = 3
    while i + 1 < flds.size
      t = time_to_minutes(flds[i])
      break unless t
      points << [t, flds[i + 1].to_s]
      i += 2
    end
    points
  end

  # Returns the value from a [(minutes, value)] list that applies at query_mins.
  def lookup_value_at(points, query_mins)
    points.each { |t, v| return v if query_mins <= t }
    points.last&.last
  end

  # Builds a new set of (minutes, value) points by merging temperature and occupancy
  # breakpoints. Unoccupied periods (occ ≤ 0.1) get setback_temp; others keep temp value.
  def merge_day_setback(temp_points, occ_points, setback_temp)
    all_times = (temp_points.map(&:first) + occ_points.map(&:first)).uniq.sort
    result    = []
    prev_mins = 0

    all_times.each do |t|
      query = prev_mins + 1
      temp_val = lookup_value_at(temp_points, query) || temp_points.last&.last || "0"
      occ_val  = lookup_value_at(occ_points,  query) || "0"

      final_val = begin
        Float(occ_val) <= @occ_threshold ? setback_temp.to_s : temp_val
      rescue ArgumentError
        temp_val
      end

      result    << [t, final_val]
      prev_mins  = t
    end

    result
  end

  # Creates a modified copy of a temperature Schedule:Day:Interval with setback applied
  # during unoccupied periods derived from the corresponding occupancy day interval.
  # cache_key is (temp_day_name, occ_day_name) to allow different occ patterns per day type.
  def copy_day_interval_setback(workspace, runner, temp_day_name, new_day_name,
                                 occ_day_name, setback_temp, processed)
    cache_key = "#{temp_day_name}|||#{occ_day_name}"
    return processed[cache_key] if processed.key?(cache_key)

    temp_obj = find_by_name(workspace, "Schedule:Day:Interval", temp_day_name)
    unless temp_obj
      runner.registerWarning("Schedule:Day:Interval '#{temp_day_name}' not found.")
      processed[cache_key] = temp_day_name
      return temp_day_name
    end

    temp_flds  = fields_of(temp_obj)
    temp_points = parse_day_interval(temp_flds)
    header      = temp_flds[0..2]   # Name, TypeLimits, Interpolate

    occ_obj = find_by_name(workspace, "Schedule:Day:Interval", occ_day_name)
    new_points = if occ_obj
      occ_flds  = fields_of(occ_obj)
      occ_points = parse_day_interval(occ_flds)
      merge_day_setback(temp_points, occ_points, setback_temp)
    else
      runner.registerWarning("Occupancy day interval '#{occ_day_name}' not found; no setback for this day type.")
      temp_points
    end

    new_flds    = [new_day_name, header[1], header[2]]
    new_points.each { |t, v| new_flds << minutes_to_time(t) << v }

    add_idf_object(workspace, "Schedule:Day:Interval", new_flds)
    processed[cache_key] = new_day_name
    new_day_name
  end

  # Copies a Schedule:Year (and its Week:Daily / Day:Interval sub-objects) with
  # setback temperatures applied during unoccupied periods from occ_year_obj.
  def copy_schedule_year_setback(workspace, runner, temp_year_obj, occ_year_obj,
                                  temp_sched_name, new_sched_name, setback_temp)
    temp_year_fields = fields_of(temp_year_obj)
    occ_year_fields  = fields_of(occ_year_obj)

    # name counter ensures uniqueness when the same (temp_day, occ_day) pair first appears
    day_processed  = {}  # cache_key => new_day_name
    used_day_names = {}  # proposed_name => count, for deduplication
    week_name_map  = {}

    i = 2
    while i < temp_year_fields.size
      temp_wn = temp_year_fields[i].strip
      # Find the occ week whose date range covers the midpoint of this temp week's range,
      # rather than matching by list position (which breaks when schedules have different
      # date-range structures, e.g. one all-year entry vs. per-season entries).
      start_m = temp_year_fields[i + 1].to_i
      start_d = temp_year_fields[i + 2].to_i
      end_m   = temp_year_fields[i + 3].to_i
      end_d   = temp_year_fields[i + 4].to_i
      occ_wn  = occ_week_for_date_range(occ_year_fields, start_m, start_d, end_m, end_d)

      temp_wk_obj = find_by_name(workspace, "Schedule:Week:Daily", temp_wn)
      occ_wk_obj  = occ_wn.empty? ? nil : find_by_name(workspace, "Schedule:Week:Daily", occ_wn)

      unless temp_wk_obj
        runner.registerWarning("Schedule:Week:Daily '#{temp_wn}' not found; skipping.")
        i += 5
        next
      end

      new_wn     = derive_new_name(temp_wn, temp_sched_name, new_sched_name)
      temp_wk_fs = fields_of(temp_wk_obj)
      occ_wk_fs  = occ_wk_obj ? fields_of(occ_wk_obj) : []
      new_wk_fs  = temp_wk_fs.dup
      new_wk_fs[0] = new_wn

      (1...temp_wk_fs.size).each do |fi|
        orig_dn = temp_wk_fs[fi]
        next if orig_dn.strip.empty?

        occ_dn     = (fi < occ_wk_fs.size) ? occ_wk_fs[fi] : ""
        cache_key  = "#{orig_dn}|||#{occ_dn}"

        unless day_processed.key?(cache_key)
          # Build a unique name for this (temp_day, occ_day) combination
          base = derive_new_name(orig_dn, temp_sched_name, new_sched_name)
          used_day_names[base] ||= 0
          used_day_names[base] += 1
          # Only append counter when there are multiple entries for this base name
          proposed_name = base
          # We'll rename after collecting all; for now register with count
          # Actually: first occurrence keeps base name; later collisions get index
          if used_day_names[base] > 1
            # Check if this same cache_key was already seen under the base name
            existing = day_processed.values.find { |n| n.start_with?(base) }
            proposed_name = "#{base} #{used_day_names[base]}" if existing
          end

          copy_day_interval_setback(
            workspace, runner, orig_dn, proposed_name, occ_dn, setback_temp, day_processed
          )
          # Override the hash entry to use proposed_name in case copy used a fallback
          day_processed[cache_key] = proposed_name unless day_processed.key?(cache_key)
        end

        new_wk_fs[fi] = day_processed[cache_key]
      end

      unless add_idf_object(workspace, "Schedule:Week:Daily", new_wk_fs)
        runner.registerError("Failed to create Schedule:Week:Daily '#{new_wn}'.")
        return false
      end
      week_name_map[temp_wn] = new_wn
      i += 5
    end

    new_year_fields    = temp_year_fields.dup
    new_year_fields[0] = new_sched_name
    i = 2
    while i < new_year_fields.size
      wn = new_year_fields[i]
      new_year_fields[i] = week_name_map[wn] if week_name_map.key?(wn)
      i += 5
    end

    unless add_idf_object(workspace, "Schedule:Year", new_year_fields)
      runner.registerError("Failed to create Schedule:Year '#{new_sched_name}'.")
      return false
    end
    true
  end

  # Returns the occupancy week name whose date range contains the midpoint of the
  # given temperature/humidity week date range. Falls back to the last occ week found
  # when no range contains the midpoint (should not occur with valid IDF).
  def occ_week_for_date_range(occ_year_fields, s_m, s_d, e_m, e_d)
    mid = (day_of_year(s_m, s_d) + day_of_year(e_m, e_d)) / 2
    last_wn = ""
    j = 2
    while j + 4 < occ_year_fields.size
      wn    = occ_year_fields[j].strip
      o_s   = day_of_year(occ_year_fields[j + 1].to_i, occ_year_fields[j + 2].to_i)
      o_e   = day_of_year(occ_year_fields[j + 3].to_i, occ_year_fields[j + 4].to_i)
      last_wn = wn
      return wn if mid >= o_s && mid <= o_e
      j += 5
    end
    last_wn
  end

  # Approximate day-of-year (1-based, non-leap-year).
  def day_of_year(month, day)
    month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return day if month <= 1
    month_lengths[0...(month - 1)].sum + day
  end

  # Returns a new sub-object name by replacing the parent schedule name prefix.
  # Falls back to prepending new_parent if the substitution has no effect.
  def derive_new_name(sub_name, orig_parent, new_parent)
    result = sub_name.sub(orig_parent, new_parent)
    result == sub_name ? "#{new_parent} #{sub_name}" : result
  end
end

VAVTerminalUnoccupiedSetbackEnergyPlus.new.registerWithApplication
