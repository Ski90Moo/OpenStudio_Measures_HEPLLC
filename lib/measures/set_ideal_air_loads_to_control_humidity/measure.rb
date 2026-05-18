# *******************************************************************************
# Helix Energy Partners LLC (R), copyright (c) 2026
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the
# trademark, "HEPLLC", "HEP", or any other confusingly similar designation without
# specific prior written permission from Helix Energy Partners LLC
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ****************************************************

# start the measure
class SetIdealAirLoadsToControlHumidity < OpenStudio::Measure::EnergyPlusMeasure

  def name
    return "Set IdealAirLoads to Control Humidity"
  end
  def description
    return "Configures humidity controls on the HVACTemplate:Zone:IdealLoadsAirSystem for a specified thermal zone. Reads the zone's ZoneControl:Humidistat, computes daily average setpoints from its humidifying and dehumidifying schedules, and applies them along with the user-selected control types to the ideal loads object. Dehumidification supports Humidistat, ConstantSensibleHeatRatio, ConstantSupplyHumidityRatio, and None. Humidification supports Humidistat, ConstantSupplyHumidityRatio, and None. The humidistat object and its referenced schedules are deleted from the model after processing."
  end
  def modeler_description
    return "Locates ZoneControl:Humidistat for the specified zone and traces its humidifying and dehumidifying schedule references through the Schedule:Year to Schedule:Week:Daily to Schedule:Day:Interval/Hourly chain to compute a daily weighted average for each setpoint. The averages are written to the Humidification Setpoint and Dehumidification Setpoint fields of HVACTemplate:Zone:IdealLoadsAirSystem. When ConstantSupplyHumidityRatio is selected, the Minimum Cooling Supply Humidity Ratio or Maximum Heating Supply Humidity Ratio field is set from the user-supplied humidity ratio value. The ZoneControl:Humidistat and its referenced schedule objects are then removed from the workspace. LIMITATION: The IdealLoadsAirSystem Humidistat dehumidification control is simplified—it is not a full dehumidification-with-reheat system and therefore will not provide accurate accounting of energy use for humidity control."
  end

  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    thermal_zone_name = OpenStudio::Measure::OSArgument.makeStringArgument('thermal_zone_name', true)
    thermal_zone_name.setDisplayName('Thermal Zone Name')
    thermal_zone_name.setDescription('Enter the exact thermal zone name (e.g., TZ:01-FCU-29B-BAKERY-DINING)')
    thermal_zone_name.setDefaultValue('TZ:01-FCU-29B-BAKERY-DINING')
    args << thermal_zone_name

    ideal_loads_dehumid_control_type = OpenStudio::Measure::OSArgument.makeStringArgument('ideal_loads_dehumidification_control_type', false)
    ideal_loads_dehumid_control_type.setDisplayName('Dehumidification Control Type (Ideal Loads)')
    ideal_loads_dehumid_control_type.setDescription('Enter: ConstantSensibleHeatRatio, Humidistat, ConstantSupplyHumidityRatio, or None')
    ideal_loads_dehumid_control_type.setDefaultValue('Humidistat')
    args << ideal_loads_dehumid_control_type

    ideal_loads_humid_control_type = OpenStudio::Measure::OSArgument.makeStringArgument('ideal_loads_humidification_control_type', false)
    ideal_loads_humid_control_type.setDisplayName('Humidification Control Type (Ideal Loads)')
    ideal_loads_humid_control_type.setDescription('Enter: Humidistat, ConstantSupplyHumidityRatio, or None')
    ideal_loads_humid_control_type.setDefaultValue('Humidistat')
    args << ideal_loads_humid_control_type

    dehumid_supply_hr = OpenStudio::Measure::OSArgument.makeDoubleArgument('dehumidification_supply_humidity_ratio', false)
    dehumid_supply_hr.setDisplayName('Dehumidification Constant Supply Humidity Ratio (kgWater/kgDryAir)')
    dehumid_supply_hr.setDescription('Used when Dehumidification Control Type is ConstantSupplyHumidityRatio. Sets Minimum Cooling Supply Humidity Ratio.')
    dehumid_supply_hr.setDefaultValue(0.008)
    args << dehumid_supply_hr

    humid_supply_hr = OpenStudio::Measure::OSArgument.makeDoubleArgument('humidification_supply_humidity_ratio', false)
    humid_supply_hr.setDisplayName('Humidification Constant Supply Humidity Ratio (kgWater/kgDryAir)')
    humid_supply_hr.setDescription('Used when Humidification Control Type is ConstantSupplyHumidityRatio. Sets Maximum Heating Supply Humidity Ratio.')
    humid_supply_hr.setDefaultValue(0.008)
    args << humid_supply_hr

    return args
  end

  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    thermal_zone_name = runner.getStringArgumentValue('thermal_zone_name', user_arguments)
    ideal_loads_dehumid_control_type = runner.getOptionalStringArgumentValue('ideal_loads_dehumidification_control_type', user_arguments)
    ideal_loads_humid_control_type = runner.getOptionalStringArgumentValue('ideal_loads_humidification_control_type', user_arguments)
    dehumid_supply_hr = runner.getOptionalDoubleArgumentValue('dehumidification_supply_humidity_ratio', user_arguments)
    humid_supply_hr   = runner.getOptionalDoubleArgumentValue('humidification_supply_humidity_ratio', user_arguments)

    # ========== STEP 1: Find ZoneControl:Humidistat for the thermal zone ==========

    humidistat = nil
    workspace.getObjectsByType('ZoneControl:Humidistat'.to_IddObjectType).each do |obj|
      if obj.getString(1).to_s.strip == thermal_zone_name.strip
        humidistat = obj
        break
      end
    end

    if humidistat.nil?
      runner.registerError("Could not find ZoneControl:Humidistat for zone '#{thermal_zone_name}'.")
      return false
    end

    humidifying_schedule_name   = humidistat.getString(2).to_s.strip
    dehumidifying_schedule_name = humidistat.getString(3).to_s.strip
    runner.registerInitialCondition("Found ZoneControl:Humidistat '#{humidistat.getString(0)}' for zone '#{thermal_zone_name}'. " \
      "Humidifying schedule: '#{humidifying_schedule_name}', Dehumidifying schedule: '#{dehumidifying_schedule_name}'.")

    # ========== STEP 2: Compute daily average setpoints from schedules ==========

    humidifying_setpoint = nil
    unless humidifying_schedule_name.empty?
      humidifying_setpoint = compute_schedule_daily_average(workspace, runner, humidifying_schedule_name)
      if humidifying_setpoint.nil?
        runner.registerError("Could not compute daily average for humidifying schedule '#{humidifying_schedule_name}'.")
        return false
      end
      runner.registerInfo("Computed Humidification Setpoint (daily avg): #{humidifying_setpoint.round(1)}%")
    end

    dehumidifying_setpoint = nil
    unless dehumidifying_schedule_name.empty?
      dehumidifying_setpoint = compute_schedule_daily_average(workspace, runner, dehumidifying_schedule_name)
      if dehumidifying_setpoint.nil?
        runner.registerError("Could not compute daily average for dehumidifying schedule '#{dehumidifying_schedule_name}'.")
        return false
      end
      runner.registerInfo("Computed Dehumidification Setpoint (daily avg): #{dehumidifying_setpoint.round(1)}%")
    end

    # ========== STEP 3: Modify HVACTemplate:Zone:IdealLoadsAirSystem ==========

    ideal_loads_object = nil
    ideal_loads_objects = workspace.getObjectsByType('HVACTemplate:Zone:IdealLoadsAirSystem'.to_IddObjectType)

    if ideal_loads_objects.size == 0
      runner.registerWarning("No HVACTemplate:Zone:IdealLoadsAirSystem objects found in workspace.")
    else
      runner.registerInfo("Found #{ideal_loads_objects.size} HVACTemplate:Zone:IdealLoadsAirSystem objects:")
      ideal_loads_objects.each do |obj|
        zone_name = obj.getString(0).to_s
        runner.registerInfo("  - Zone: '#{zone_name}'")
        if zone_name == thermal_zone_name
          ideal_loads_object = obj
          runner.registerInfo("    MATCH FOUND!")
        end
      end
    end

    if ideal_loads_object.nil?
      runner.registerWarning("Could not find HVACTemplate:Zone:IdealLoadsAirSystem for zone '#{thermal_zone_name}'. Skipping ideal loads modifications.")
    else
      idd_object = ideal_loads_object.iddObject
      dehumid_control_index    = nil
      humid_control_index      = nil
      dehumid_setpoint_index   = nil
      humid_setpoint_index     = nil
      min_cooling_hr_index     = nil
      max_heating_hr_index     = nil

      for i in 0...idd_object.numFields
        field_optional = idd_object.getField(i)
        next unless field_optional.is_initialized
        case field_optional.get.name
        when 'Dehumidification Control Type'       then dehumid_control_index  = i
        when 'Humidification Control Type'         then humid_control_index    = i
        when 'Dehumidification Setpoint'           then dehumid_setpoint_index = i
        when 'Humidification Setpoint'             then humid_setpoint_index   = i
        when 'Minimum Cooling Supply Humidity Ratio' then min_cooling_hr_index = i
        when 'Maximum Heating Supply Humidity Ratio' then max_heating_hr_index = i
        end
      end

      if dehumid_control_index.nil?
        runner.registerWarning("Could not find 'Dehumidification Control Type' field in HVACTemplate:Zone:IdealLoadsAirSystem")
      elsif ideal_loads_dehumid_control_type.is_initialized && !ideal_loads_dehumid_control_type.get.empty?
        ideal_loads_object.setString(dehumid_control_index, ideal_loads_dehumid_control_type.get)
        runner.registerInfo("  - Dehumidification Control Type set to: #{ideal_loads_dehumid_control_type.get}")
      end

      if humid_control_index.nil?
        runner.registerWarning("Could not find 'Humidification Control Type' field in HVACTemplate:Zone:IdealLoadsAirSystem")
      elsif ideal_loads_humid_control_type.is_initialized && !ideal_loads_humid_control_type.get.empty?
        ideal_loads_object.setString(humid_control_index, ideal_loads_humid_control_type.get)
        runner.registerInfo("  - Humidification Control Type set to: #{ideal_loads_humid_control_type.get}")
      end

      if dehumid_setpoint_index.nil?
        runner.registerWarning("Could not find 'Dehumidification Setpoint' field in HVACTemplate:Zone:IdealLoadsAirSystem")
      elsif dehumidifying_setpoint
        ideal_loads_object.setDouble(dehumid_setpoint_index, dehumidifying_setpoint)
        runner.registerInfo("  - Dehumidification Setpoint set to: #{dehumidifying_setpoint.round(1)}%")
      end

      if humid_setpoint_index.nil?
        runner.registerWarning("Could not find 'Humidification Setpoint' field in HVACTemplate:Zone:IdealLoadsAirSystem")
      elsif humidifying_setpoint
        ideal_loads_object.setDouble(humid_setpoint_index, humidifying_setpoint)
        runner.registerInfo("  - Humidification Setpoint set to: #{humidifying_setpoint.round(1)}%")
      end

      if ideal_loads_dehumid_control_type.is_initialized && ideal_loads_dehumid_control_type.get == 'ConstantSupplyHumidityRatio'
        if min_cooling_hr_index.nil?
          runner.registerWarning("Could not find 'Minimum Cooling Supply Humidity Ratio' field in HVACTemplate:Zone:IdealLoadsAirSystem")
        elsif dehumid_supply_hr.is_initialized
          ideal_loads_object.setDouble(min_cooling_hr_index, dehumid_supply_hr.get)
          runner.registerInfo("  - Minimum Cooling Supply Humidity Ratio set to: #{dehumid_supply_hr.get} kgWater/kgDryAir")
        end
      end

      if ideal_loads_humid_control_type.is_initialized && ideal_loads_humid_control_type.get == 'ConstantSupplyHumidityRatio'
        if max_heating_hr_index.nil?
          runner.registerWarning("Could not find 'Maximum Heating Supply Humidity Ratio' field in HVACTemplate:Zone:IdealLoadsAirSystem")
        elsif humid_supply_hr.is_initialized
          ideal_loads_object.setDouble(max_heating_hr_index, humid_supply_hr.get)
          runner.registerInfo("  - Maximum Heating Supply Humidity Ratio set to: #{humid_supply_hr.get} kgWater/kgDryAir")
        end
      end

      runner.registerInfo("Successfully modified HVACTemplate:Zone:IdealLoadsAirSystem for zone '#{thermal_zone_name}'.")
    end

    # ========== STEP 4: Delete ZoneControl:Humidistat and its schedules ==========

    handles_to_remove = [humidistat.handle]

    all_schedules = []
    all_schedules.concat(workspace.getObjectsByType('Schedule:Compact'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Constant'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:File'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Year'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Week:Daily'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Week:Compact'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Day:Hourly'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Day:Interval'.to_IddObjectType))
    all_schedules.concat(workspace.getObjectsByType('Schedule:Day:List'.to_IddObjectType))

    [humidifying_schedule_name, dehumidifying_schedule_name].each do |sched_name|
      next if sched_name.empty?
      all_schedules.each do |sched|
        if sched.getString(0).to_s.strip == sched_name
          handles_to_remove << sched.handle
          runner.registerInfo("  Queued for deletion: schedule '#{sched_name}'")
          break
        end
      end
    end

    workspace.removeObjects(handles_to_remove)
    runner.registerInfo("Deleted ZoneControl:Humidistat '#{humidistat.getString(0)}' and its associated schedules.")

    runner.registerFinalCondition("Measure complete for zone '#{thermal_zone_name}'. " \
      "Humidification Setpoint: #{humidifying_setpoint ? "#{humidifying_setpoint.round(1)}%" : 'not set'}. " \
      "Dehumidification Setpoint: #{dehumidifying_setpoint ? "#{dehumidifying_setpoint.round(1)}%" : 'not set'}.")

    return true
  end

  # Dispatches to the appropriate parser based on schedule object type.
  # Supported: Schedule:Constant, Schedule:Compact, Schedule:Year,
  #            Schedule:Day:Hourly, Schedule:Day:Interval
  def compute_schedule_daily_average(workspace, runner, schedule_name)
    return nil if schedule_name.nil? || schedule_name.empty?
    sched_name = schedule_name.strip

    # Schedule:Constant — single value IS the daily average
    workspace.getObjectsByType('Schedule:Constant'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == sched_name
      return obj.getString(2).to_s.to_f
    end

    # Schedule:Compact — weighted average over the first complete 24-hour day block
    workspace.getObjectsByType('Schedule:Compact'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == sched_name
      return compact_daily_average(obj)
    end

    # Schedule:Year — trace to first week schedule, then first weekday, then day schedule
    workspace.getObjectsByType('Schedule:Year'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == sched_name
      week_name = obj.getString(2).to_s.strip  # field 2 = first Schedule:Week name
      runner.registerInfo("  Schedule:Year '#{sched_name}' → week schedule '#{week_name}'")
      return week_schedule_daily_average(workspace, runner, week_name)
    end

    # Schedule:Day:Hourly — 24 hourly values at fields 2-25 (sometimes referenced directly)
    workspace.getObjectsByType('Schedule:Day:Hourly'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == sched_name
      return day_hourly_average(obj)
    end

    # Schedule:Day:Interval — Until:HH:MM / value pairs starting at field 3
    workspace.getObjectsByType('Schedule:Day:Interval'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == sched_name
      return day_interval_average(obj)
    end

    # Not found in any supported type — report what type it actually is for diagnosis
    schedule_types = [
      'Schedule:Compact', 'Schedule:Constant', 'Schedule:File',
      'Schedule:Year', 'Schedule:Week:Daily', 'Schedule:Week:Compact',
      'Schedule:Day:Hourly', 'Schedule:Day:Interval', 'Schedule:Day:List'
    ]
    schedule_types.each do |type_str|
      workspace.getObjectsByType(type_str.to_IddObjectType).each do |obj|
        if obj.getString(0).to_s.strip == sched_name
          runner.registerWarning("Schedule '#{sched_name}' found as type '#{type_str}' which is not supported for daily average computation.")
          return nil
        end
      end
    end

    runner.registerWarning("Schedule '#{sched_name}' not found in workspace.")
    nil
  end

  def compact_daily_average(obj)
    num_fields   = obj.numFields
    prev_hour    = 0.0
    weighted_sum = 0.0
    i = 2
    while i < num_fields
      raw   = obj.getString(i).to_s.strip
      lower = raw.downcase
      if lower.start_with?('through:') || lower.start_with?('for:')
        prev_hour    = 0.0
        weighted_sum = 0.0
        i += 1
        next
      elsif lower.start_with?('until:')
        time_str     = raw.sub(/until:\s*/i, '')
        parts        = time_str.split(':')
        current_hour = parts[0].to_f + (parts[1] ? parts[1].to_f / 60.0 : 0.0)
        if i + 1 < num_fields
          value         = obj.getString(i + 1).to_s.to_f
          weighted_sum += value * (current_hour - prev_hour)
          prev_hour     = current_hour
        end
        i += 2
        return weighted_sum / 24.0 if prev_hour >= 24.0
        next
      end
      i += 1
    end
    prev_hour > 0 ? weighted_sum / prev_hour : nil
  end

  def week_schedule_daily_average(workspace, runner, week_schedule_name)
    workspace.getObjectsByType('Schedule:Week:Daily'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == week_schedule_name.strip
      # Field 2 = Monday day schedule (representative weekday)
      day_name = obj.getString(2).to_s.strip
      runner.registerInfo("  Schedule:Week:Daily '#{week_schedule_name}' → day schedule '#{day_name}'")
      return day_schedule_average(workspace, runner, day_name)
    end

    workspace.getObjectsByType('Schedule:Week:Compact'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == week_schedule_name.strip
      # Schedule:Week:Compact: extensible DayType/ScheduleDay pairs starting at field 1
      # Use the first Schedule:Day name found (field 2, after the first day-type keyword)
      day_name = obj.getString(2).to_s.strip
      runner.registerInfo("  Schedule:Week:Compact '#{week_schedule_name}' → day schedule '#{day_name}'")
      return day_schedule_average(workspace, runner, day_name)
    end

    runner.registerWarning("Week schedule '#{week_schedule_name}' not found.")
    nil
  end

  def day_schedule_average(workspace, runner, day_schedule_name)
    workspace.getObjectsByType('Schedule:Day:Hourly'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == day_schedule_name.strip
      return day_hourly_average(obj)
    end

    workspace.getObjectsByType('Schedule:Day:Interval'.to_IddObjectType).each do |obj|
      next unless obj.getString(0).to_s.strip == day_schedule_name.strip
      return day_interval_average(obj)
    end

    runner.registerWarning("Day schedule '#{day_schedule_name}' not found (tried Schedule:Day:Hourly and Schedule:Day:Interval).")
    nil
  end

  # Fields 2-25 are the 24 hourly values
  def day_hourly_average(obj)
    total = 0.0
    (2..25).each { |i| total += obj.getString(i).to_s.to_f }
    total / 24.0
  end

  # Fields: 0=Name, 1=TypeLimits, 2=Interpolate, then extensible HH:MM / value pairs.
  # Time fields are bare strings like "24:00" or "8:30" with no "Until:" prefix.
  def day_interval_average(obj)
    num_fields   = obj.numFields
    prev_hour    = 0.0
    weighted_sum = 0.0
    i = 3  # skip Name, TypeLimits, Interpolate
    while i < num_fields
      raw = obj.getString(i).to_s.strip
      if raw.match?(/^\d+:\d+$/)
        parts        = raw.split(':')
        current_hour = parts[0].to_f + parts[1].to_f / 60.0
        if i + 1 < num_fields
          value         = obj.getString(i + 1).to_s.to_f
          weighted_sum += value * (current_hour - prev_hour)
          prev_hour     = current_hour
        end
        i += 2
        next
      end
      i += 1
    end
    return weighted_sum / 24.0 if prev_hour >= 24.0
    prev_hour > 0 ? weighted_sum / prev_hour : nil
  end

end

SetIdealAirLoadsToControlHumidity.new.registerWithApplication
