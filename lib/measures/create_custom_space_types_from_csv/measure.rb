# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'

# start the measure
class CreateCustomSpaceTypesFromCSV < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Create Custom Space Types From CSV'
  end

  # human readable description
  def description
    return 'The user can enter custom data into a space type csv file and a schedules csv file.  From these, the measure generates the requested space types.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The user can enter custom data into a space type csv file and a schedules csv file.  From these, the measure generates the requested space types.  Key information is identified with the OS: and !- tags; these columns must be completed in order for the measure to run.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Path to SpaceTypes.csv file
    space_types_csv_path = OpenStudio::Measure::OSArgument.makeStringArgument('space_types_csv_path', true)
    space_types_csv_path.setDisplayName('Path to SpaceTypes.csv')
    space_types_csv_path.setDescription('Full file path to the SpaceTypes.csv file containing space type definitions.')
    space_types_csv_path.setDefaultValue('resources/SpaceTypes.csv')
    args << space_types_csv_path

    # Path to Schedules.csv file
    schedules_csv_path = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_csv_path', true)
    schedules_csv_path.setDisplayName('Path to Schedules.csv')
    schedules_csv_path.setDescription('Full file path to the Schedules.csv file containing schedule definitions.')
    schedules_csv_path.setDefaultValue('resources/Schedules.csv')
    args << schedules_csv_path

    return args
  end

  # Helper method to get column index by UUID
  def get_column_index(headers, uuid)
    headers.index(uuid)
  end

  # Helper method to get value from row by UUID
  def get_value_by_uuid(row, headers, uuid)
    index = get_column_index(headers, uuid)
    return nil if index.nil?
    return nil if row.nil? || index >= row.size
    value = row[index]
    return nil if value.nil?
    
    # Handle string values
    value_str = value.to_s.strip
    return nil if value_str.empty?
    return value_str
  end

  # Helper method to optimize hourly schedule values
  # Compresses consecutive duplicate values into single time/value pairs
  def optimize_hourly_values(row)
    # Collect all 24 hourly values
    hourly_values = []
    (1..24).each do |hour|
      value = row["Hr #{hour}"]
      hourly_values << (value.nil? || value.empty? ? nil : value.to_f)
    end
    
    # Find transition points where value changes
    optimized = []
    current_value = hourly_values[0]
    
    (1..23).each do |hour|
      next_value = hourly_values[hour]
      
      # If value changes, record the end of the current sequence
      if next_value != current_value
        optimized << { hour: hour, value: current_value }
        current_value = next_value
      end
    end
    
    # Always add the final hour
    optimized << { hour: 24, value: current_value }
    
    return optimized
  end

  # Helper method to create schedule from Schedules.csv
  def create_schedule_from_csv(model, runner, schedule_name, schedules_data, created_schedules)
    # Check if schedule already created
    return created_schedules[schedule_name] if created_schedules.key?(schedule_name)

    # Find schedule rows with matching name
    schedule_rows = schedules_data.select { |row| row['Name'] == schedule_name }
    
    if schedule_rows.empty?
      runner.registerWarning("Schedule '#{schedule_name}' not found in Schedules.csv")
      return nil
    end

    # Create ScheduleRuleset
    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(schedule_name)
    
    # Store in hash immediately to prevent duplicate creation
    created_schedules[schedule_name] = schedule
    
    # Track which day types have been created for this schedule to prevent duplicates
    created_day_types = {}

    # Get units if available
    units = schedule_rows.first['Units']
    
    # Set schedule type limits based on units
    if !units.nil? && !units.empty?
      if units.upcase == 'C'
        # Temperature schedule
        schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
        schedule_type_limits.setName("#{schedule_name} Type Limits")
        schedule_type_limits.setUnitType('Temperature')
        schedule.setScheduleTypeLimits(schedule_type_limits)
      elsif units.upcase == 'W'
        # Power/Activity schedule
        schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
        schedule_type_limits.setName("#{schedule_name} Type Limits")
        schedule_type_limits.setUnitType('Power')
        schedule.setScheduleTypeLimits(schedule_type_limits)
      end
    end

    # Process each schedule row
    schedule_rows.each do |row|
      day_types = row['Day Types']
      schedule_type = row['Type']
      start_date_str = row['Start Date']
      end_date_str = row['End Date']
      
      # Skip if essential fields are missing
      if day_types.nil? || day_types.empty? || schedule_type.nil? || schedule_type.empty?
        runner.registerWarning("Skipping schedule row with missing day types or schedule type for #{schedule_name}")
        next
      end
      
      # Parse dates - handle both "Jan-1" and "1-Jan" formats
      start_parts = start_date_str.to_s.split('-')
      end_parts = end_date_str.to_s.split('-')
      
      # Map month names to numbers
      month_map = {
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6,
        'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
      }
      
      # Detect format: if first part is in month_map, it's Month-Day, otherwise Day-Month
      if start_parts.length == 2
        if month_map.key?(start_parts[0])
          # Format: Month-Day (e.g., "Jan-1")
          start_month = start_parts[0]
          start_day = start_parts[1]
        else
          # Format: Day-Month (e.g., "1-Jan")
          start_day = start_parts[0]
          start_month = start_parts[1]
        end
      else
        start_month = nil
        start_day = nil
      end
      
      if end_parts.length == 2
        if month_map.key?(end_parts[0])
          # Format: Month-Day (e.g., "Dec-31")
          end_month = end_parts[0]
          end_day = end_parts[1]
        else
          # Format: Day-Month (e.g., "31-Dec")
          end_day = end_parts[0]
          end_month = end_parts[1]
        end
      else
        end_month = nil
        end_day = nil
      end
      
      start_month_num = month_map[start_month]
      end_month_num = month_map[end_month]
      
      # Check if dates are valid (check for nil or empty)
      start_day_valid = !start_day.nil? && !start_day.empty?
      end_day_valid = !end_day.nil? && !end_day.empty?
      dates_valid = !start_month_num.nil? && !end_month_num.nil? && start_day_valid && end_day_valid
      
      # Validate dates (needed for ScheduleRules, not for Default day type)
      # Only process rows with 'Default' OR rows with valid dates
      has_default = day_types.to_s.include?('Default')
      
      if !has_default && !dates_valid
        runner.registerWarning("Skipping schedule row with invalid dates for #{schedule_name}: Start=#{start_date_str}, End=#{end_date_str}, DayTypes=#{day_types}")
        next
      end
      
      # Split day types by pipe
      day_type_list = day_types.split('|').map(&:strip)
      
      day_type_list.each do |day_type|
        # Skip if this day type has already been created for this schedule
        if created_day_types.key?(day_type)
          runner.registerWarning("Skipping duplicate day type '#{day_type}' for schedule '#{schedule_name}'")
          next
        end
        
        if day_type == 'Default'
          # Modify the default day schedule directly
          default_day_sched = schedule.defaultDaySchedule
          default_day_sched.setName("SchDay_#{schedule_name}_Default")
          default_day_sched.clearValues
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            default_day_sched.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              default_day_sched.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'WntrDsn'
          # Winter Design Day - must create NEW object to avoid overwriting default
          winter_day = OpenStudio::Model::ScheduleDay.new(model)
          winter_day.setName("SchDay_#{schedule_name}_WntrDsn")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            winter_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              winter_day.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          schedule.setWinterDesignDaySchedule(winter_day)
          created_day_types[day_type] = true
        elsif day_type == 'SmrDsn'
          # Summer Design Day - must create NEW object to avoid overwriting default
          summer_day = OpenStudio::Model::ScheduleDay.new(model)
          summer_day.setName("SchDay_#{schedule_name}_SmrDsn")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            summer_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              summer_day.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          schedule.setSummerDesignDaySchedule(summer_day)
          created_day_types[day_type] = true
        elsif day_type == 'Wkdy'
          # Weekday rule - skip if dates are invalid
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Wkdy rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Wkdy")
          rule.setApplyMonday(true)
          rule.setApplyTuesday(true)
          rule.setApplyWednesday(true)
          rule.setApplyThursday(true)
          rule.setApplyFriday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Wkdy")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Wknd'
          # Weekend rule - skip if dates are invalid
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Wknd rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Wknd")
          rule.setApplySaturday(true)
          rule.setApplySunday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Wknd")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Mon'
          # Monday rule - skip if dates are invalid
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Mon rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Mon")
          rule.setApplyMonday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Mon")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Tue'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Tue rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Tue")
          rule.setApplyTuesday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Tue")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Wed'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Wed rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Wed")
          rule.setApplyWednesday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Wed")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Thu'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Thu rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Thu")
          rule.setApplyThursday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Thu")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Fri'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Fri rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Fri")
          rule.setApplyFriday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Fri")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Sat'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Sat rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Sat")
          rule.setApplySaturday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Sat")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Sun'
          if start_month_num.nil? || end_month_num.nil?
            runner.registerWarning("Skipping Sun rule for #{schedule_name} due to invalid dates")
            next
          end
          # Create rule first, then get its day schedule
          rule = OpenStudio::Model::ScheduleRule.new(schedule)
          rule.setName("SchRule_#{schedule_name}_Sun")
          rule.setApplySunday(true)
          rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month_num), start_day.to_i))
          rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month_num), end_day.to_i))
          # Get the day schedule from the rule and modify it
          day_schedule = rule.daySchedule
          day_schedule.setName("SchDay_#{schedule_name}_Sun")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          created_day_types[day_type] = true
        elsif day_type == 'Hol'
          # Holiday schedule - must create NEW object to avoid overwriting default
          day_schedule = OpenStudio::Model::ScheduleDay.new(model)
          day_schedule.setName("SchDay_#{schedule_name}_Hol")
          if schedule_type == 'Constant'
            value = row["Hr 1"].to_f
            day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif schedule_type == 'Hourly'
            # Use optimized values to avoid duplicates
            optimized_values = optimize_hourly_values(row)
            optimized_values.each do |time_value|
              day_schedule.addValue(OpenStudio::Time.new(0, time_value[:hour], 0, 0), time_value[:value])
            end
          end
          schedule.setHolidaySchedule(day_schedule)
          created_day_types[day_type] = true
        end
      end
    end

    # Store in hash to avoid recreating
    created_schedules[schedule_name] = schedule
    runner.registerInfo("Created schedule: #{schedule_name}")
    
    return schedule
  end

  # Create an ActivityLevel schedule with constant values for default, summer, and winter design days
  def create_activity_level_schedule(model, schedule_name, default_value, summer_value, winter_value, runner)
    # Create the schedule ruleset
    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(schedule_name)
    
    # Set schedule type limits to ActivityLevel
    schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    schedule_type_limits.setName("#{schedule_name} Type Limits")
    schedule_type_limits.setNumericType('Continuous')
    schedule_type_limits.setUnitType('ActivityLevel')
    schedule_type_limits.setLowerLimitValue(0.0)
    schedule.setScheduleTypeLimits(schedule_type_limits)
    
    # Default day schedule (all year when no rules apply)
    default_day = schedule.defaultDaySchedule
    default_day.setName("#{schedule_name} Default")
    default_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), default_value)
    
    # Summer Design Day schedule
    if summer_value > 0
      summer_design_day = OpenStudio::Model::ScheduleDay.new(model)
      summer_design_day.setName("#{schedule_name} Summer Design Day")
      summer_design_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), summer_value)
      schedule.setSummerDesignDaySchedule(summer_design_day)
    end
    
    # Winter Design Day schedule
    if winter_value > 0
      winter_design_day = OpenStudio::Model::ScheduleDay.new(model)
      winter_design_day.setName("#{schedule_name} Winter Design Day")
      winter_design_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), winter_value)
      schedule.setWinterDesignDaySchedule(winter_design_day)
    end
    
    runner.registerInfo("Created ActivityLevel schedule: #{schedule_name} (default: #{default_value} W, summer: #{summer_value} W, winter: #{winter_value} W)")
    
    return schedule
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)  # Do **NOT** remove this line

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    space_types_csv_path = runner.getStringArgumentValue('space_types_csv_path', user_arguments)
    schedules_csv_path = runner.getStringArgumentValue('schedules_csv_path', user_arguments)

    # Handle relative paths - make them relative to the measure directory
    measure_dir = File.dirname(__FILE__)
    
    if !File.absolute_path?(space_types_csv_path)
      space_types_csv_path = File.join(measure_dir, space_types_csv_path)
    end
    
    if !File.absolute_path?(schedules_csv_path)
      schedules_csv_path = File.join(measure_dir, schedules_csv_path)
    end

    # Check if files exist
    if !File.exist?(space_types_csv_path)
      runner.registerError("SpaceTypes.csv file not found at #{space_types_csv_path}")
      return false
    end

    if !File.exist?(schedules_csv_path)
      runner.registerError("Schedules.csv file not found at #{schedules_csv_path}")
      return false
    end

    runner.registerInfo("Reading SpaceTypes.csv from: #{space_types_csv_path}")
    runner.registerInfo("Reading Schedules.csv from: #{schedules_csv_path}")

    # Read SpaceTypes.csv with aggressive error handling
    begin
      # First, try to read and clean the file
      file_content = File.read(space_types_csv_path, encoding: 'BOM|UTF-8')
      
      # Split into lines
      lines = file_content.split(/\r?\n/)
      
      runner.registerInfo("SpaceTypes.csv has #{lines.size} lines")
      
      # Parse CSV from the cleaned content
      # Use a very liberal parser that handles most issues
      require 'csv'
      space_types_data = []
      
      # Process line by line with error recovery
      current_line = 0
      lines.each_with_index do |line, idx|
        current_line = idx + 1
        begin
          # Try to parse this line as CSV
          # Split on commas but be careful with quoted fields
          parsed_line = CSV.parse_line(line, liberal_parsing: true, quote_char: '"')
          space_types_data << parsed_line if parsed_line
        rescue CSV::MalformedCSVError => e
          # If a single line fails, try to salvage it
          runner.registerWarning("Issue parsing line #{current_line}: #{e.message}. Attempting to salvage...")
          # Try simple comma split as fallback
          salvaged = line.split(',').map { |field| field.strip.gsub(/^"|"$/, '') }
          space_types_data << salvaged
        rescue => e
          runner.registerWarning("Skipping malformed line #{current_line}: #{e.message}")
          # Skip this line entirely
        end
      end
      
      if space_types_data.empty?
        runner.registerError("Could not read any data from SpaceTypes.csv")
        return false
      end
      
    rescue => e
      runner.registerError("Fatal error reading SpaceTypes.csv: #{e.message}")
      runner.registerError("#{e.class}: #{e.backtrace.first}")
      return false
    end
    
    headers = space_types_data[0].map { |h| h.to_s.strip }
    data_rows = space_types_data[1..-1]

    runner.registerInfo("SpaceTypes.csv has #{headers.size} columns and #{data_rows.size} data rows")
    runner.registerInfo("First few header UUIDs: #{headers[0..4].join(', ')}")
    
    # Debug: Check if CATEGORY UUID exists in headers
    category_uuid = 'd83d8e85-c973-43f1-8010-e8f36dc62725'
    category_index = headers.index(category_uuid)
    if category_index.nil?
      runner.registerWarning("CATEGORY UUID '#{category_uuid}' not found in headers!")
      runner.registerInfo("Available UUIDs: #{headers.join(', ')}")
    else
      runner.registerInfo("CATEGORY UUID found at column index #{category_index}")
      # Show first few category values
      sample_categories = data_rows[0..2].map { |row| row[category_index] }.compact
      runner.registerInfo("Sample CATEGORY values: #{sample_categories.join(', ')}")
    end

    # Read Schedules.csv with aggressive error handling
    # Note: First 2 rows are descriptive/comment rows, row 3 is the header
    begin
      # Read and clean the file
      file_content = File.read(schedules_csv_path, encoding: 'BOM|UTF-8')
      lines = file_content.split(/\r?\n/)
      
      runner.registerInfo("Schedules.csv has #{lines.size} lines")
      
      # Parse line by line
      schedules_csv = []
      lines.each_with_index do |line, idx|
        begin
          parsed_line = CSV.parse_line(line, liberal_parsing: true, quote_char: '"')
          schedules_csv << parsed_line if parsed_line
        rescue CSV::MalformedCSVError => e
          runner.registerWarning("Issue parsing Schedules.csv line #{idx + 1}: #{e.message}. Attempting to salvage...")
          salvaged = line.split(',').map { |field| field.strip.gsub(/^"|"$/, '') }
          schedules_csv << salvaged
        rescue => e
          runner.registerWarning("Skipping malformed Schedules.csv line #{idx + 1}: #{e.message}")
        end
      end
      
      if schedules_csv.size < 4
        runner.registerError("Schedules.csv doesn't have enough rows (need at least 4: 2 comments + header + data)")
        return false
      end
      
    rescue => e
      runner.registerError("Fatal error reading Schedules.csv: #{e.message}")
      return false
    end
    
    # Skip first 2 rows (comments/descriptions) and use row 3 as headers
    headers_row = schedules_csv[2]
    data_rows_schedules = schedules_csv[3..-1]
    
    # Convert to array of hashes for easier access
    schedules_data = []
    data_rows_schedules.each do |row|
      row_hash = {}
      headers_row.each_with_index do |header, index|
        row_hash[header] = row[index]
      end
      schedules_data << row_hash
    end

    # Track created schedules to avoid duplicates
    created_schedules = {}

    # UUID definitions
    category_uuid = 'd83d8e85-c973-43f1-8010-e8f36dc62725'
    rgb_r_uuid = 'bb3bf4f1-c80b-43b9-93a6-263313c59141'
    rgb_g_uuid = 'f48c2a4a-3151-4163-b625-b93c6c227f62'
    rgb_b_uuid = '35292a8f-2c31-428e-b12b-ecb42e41f30c'
    space_type_name_uuid = 'c318426a-e0cf-4c00-830e-9470f81507bb'
    schedule_set_name_uuid = '36715673-fabf-4b26-bcb3-54efccbcf6ca'
    
    # People UUIDs
    people_name_uuid = '0e52365f-0968-4865-98c8-5a391db72fe1'
    people_per_area_uuid = '1f550d2e-d956-4855-8f6c-850193633ba2'
    sensible_heat_fraction_uuid = '7e5f790a-2539-4f59-b04d-75858ff1caa0'
    number_of_people_schedule_uuid = '729982cd-0e35-4f56-90dd-aa3ce52c45a4'  # NEW - for occupancy fraction schedule
    occupancy_schedule_uuid = '7c329b17-a9b9-429d-87d6-8d696bb1a0f1'  # Used for activity level schedule name
    activity_default_uuid = 'f3e926b6-9054-43e5-b214-72715fea5476'
    activity_summer_uuid = 'f70f21e0-e825-4f34-a3a0-3417ba47b289'
    activity_winter_uuid = '0a44a70a-025f-4b95-b067-1905cd773228'
    
    # Outdoor Air UUIDs
    oa_name_uuid = 'f8a27cd2-f746-4301-a112-59d13e40d78d'
    oa_per_person_uuid = 'a791e0a0-108f-4ea5-ac55-ffbc9ef41f04'
    oa_per_area_uuid = '03d16ff5-015b-4c1f-89e1-fb9e8f3c323e'
    oa_ach_uuid = '41dd9f25-8df0-46e6-9f29-cceef9210ae8'
    
    # Electric Equipment UUIDs
    elec_name_uuid = '88a913cc-2e7a-402c-8f68-e04d9aea2bfe'
    elec_watts_per_area_uuid = 'dd740279-a043-472e-9440-1247838bdebd'
    elec_fraction_latent_uuid = '93c3190c-58c6-4fa6-b31d-e972f017b622'
    elec_fraction_radiant_uuid = 'e7668a0e-eeeb-49fe-b68d-e4673ff0492f'
    elec_fraction_lost_uuid = '17a128c0-8bb3-42fe-8fa8-e9b6c9857c61'
    elec_schedule_uuid = '922e17af-4f99-4a08-92d5-c8797f685f91'
    
    # Lights UUIDs
    lights_name_uuid = '8cd22776-3059-4312-be9f-414a4cc9a5d4'
    lights_watts_per_area_uuid = 'da106b8e-74c8-48ae-9585-c42116b2ba37'
    lights_fraction_radiant_uuid = '37274c8e-ef2a-4273-be16-1568ef1010d8'
    lights_fraction_visible_uuid = '2f6014cb-8ffd-48ef-8c06-e2f22e8f09fb'
    lights_schedule_uuid = '06a4bb43-86fe-4d0d-b323-df7f797ddedf'
    
    # Gas Equipment UUIDs
    gas_name_uuid = '4478951e-a465-46c5-913d-bcea7a66cb2a'
    gas_power_per_area_uuid = '75657b05-6269-49ed-9dde-0685e47cd2e8'
    gas_fraction_latent_uuid = 'd7a052b3-0fd2-4248-aceb-14699019a4a4'
    gas_fraction_radiant_uuid = 'fa38e540-d001-49d9-b3f1-d1a707fc1579'
    gas_fraction_lost_uuid = '297cff0e-3751-4d1e-8c51-b492f8bae160'
    gas_schedule_uuid = 'be6b6705-67ab-46ec-a6e5-80adf6c48c0a'
    
    # Infiltration UUIDs
    infil_name_uuid = 'f0b3db32-813a-495e-9ca0-dde8056737c8'
    infil_flow_per_area_uuid = '821df950-1005-42a1-bb71-94e21d06f843'
    infil_schedule_uuid = '94e29b50-ba90-424a-98b8-c2dc37ad1d28'

    # Counter for created space types
    space_types_created = 0
    rows_skipped = 0

    # Process each row
    data_rows.each_with_index do |row, idx|
      # Check if this row should be processed (non-empty category)
      category = get_value_by_uuid(row, headers, category_uuid)
      if category.nil?
        rows_skipped += 1
        if rows_skipped <= 3
          runner.registerInfo("Skipping row #{idx + 2} - CATEGORY is blank or nil")
        end
        next
      end

      # Get space type name
      space_type_name = get_value_by_uuid(row, headers, space_type_name_uuid)
      next if space_type_name.nil?

      runner.registerInfo("Processing space type: #{space_type_name}")

      # A. Create Space Type
      space_type = OpenStudio::Model::SpaceType.new(model)
      space_type.setName(space_type_name)

      # Set RGB rendering colors
      r = get_value_by_uuid(row, headers, rgb_r_uuid)
      g = get_value_by_uuid(row, headers, rgb_g_uuid)
      b = get_value_by_uuid(row, headers, rgb_b_uuid)
      
      if !r.nil? && !g.nil? && !b.nil?
        rendering_color = OpenStudio::Model::RenderingColor.new(model)
        rendering_color.setRenderingRedValue(r.to_i)
        rendering_color.setRenderingGreenValue(g.to_i)
        rendering_color.setRenderingBlueValue(b.to_i)
        space_type.setRenderingColor(rendering_color)
      end

      # Create DefaultScheduleSet
      schedule_set_name = get_value_by_uuid(row, headers, schedule_set_name_uuid)
      if !schedule_set_name.nil?
        schedule_set = OpenStudio::Model::DefaultScheduleSet.new(model)
        schedule_set.setName(schedule_set_name)
        space_type.setDefaultScheduleSet(schedule_set)
      else
        schedule_set = nil
      end

      # B. Create People Definition
      people_name = get_value_by_uuid(row, headers, people_name_uuid)
      if !people_name.nil?
        people_def = OpenStudio::Model::PeopleDefinition.new(model)
        people_def.setName(people_name)

        # Set people per area
        people_per_area = get_value_by_uuid(row, headers, people_per_area_uuid)
        if !people_per_area.nil?
          people_def.setPeopleperSpaceFloorArea(people_per_area.to_f)
        end

        # Set sensible heat fraction
        sensible_heat = get_value_by_uuid(row, headers, sensible_heat_fraction_uuid)
        if !sensible_heat.nil?
          people_def.setSensibleHeatFraction(sensible_heat.to_f)
        end

        # Set fraction radiant (always 0.3)
        people_def.setFractionRadiant(0.3)

        # Create People instance
        people = OpenStudio::Model::People.new(people_def)
        people.setName("#{space_type_name}_People")
        people.setSpaceType(space_type)
        people.resetMultiplier  # Keep multiplier field blank

        # Get and create Number of People (occupancy fraction) schedule
        number_of_people_sched_name = get_value_by_uuid(row, headers, number_of_people_schedule_uuid)
        if !number_of_people_sched_name.nil?
          # Create occupancy schedule from Schedules.csv
          occupancy_schedule = create_schedule_from_csv(model, runner, number_of_people_sched_name, schedules_data, created_schedules)
          if !occupancy_schedule.nil? && !schedule_set.nil?
            schedule_set.setNumberofPeopleSchedule(occupancy_schedule)
          end
        end
        
        # Get and create Activity Level schedule
        activity_sched_name = get_value_by_uuid(row, headers, occupancy_schedule_uuid)
        if !activity_sched_name.nil?
          # Get activity values from CSV
          default_activity = get_value_by_uuid(row, headers, activity_default_uuid)
          summer_activity = get_value_by_uuid(row, headers, activity_summer_uuid)
          winter_activity = get_value_by_uuid(row, headers, activity_winter_uuid)
          
          # Create the ActivityLevel schedule (constant values)
          activity_schedule = create_activity_level_schedule(
            model,
            activity_sched_name,
            default_activity.to_f,
            summer_activity.to_f,
            winter_activity.to_f,
            runner
          )
          
          # Add activity schedule to schedule set only (not to people object)
          if !activity_schedule.nil? && !schedule_set.nil?
            schedule_set.setPeopleActivityLevelSchedule(activity_schedule)
          end
        end

        runner.registerInfo("  Created People: #{people_name}")
      end

      # C. Create Design Specification Outdoor Air
      oa_name = get_value_by_uuid(row, headers, oa_name_uuid)
      if !oa_name.nil?
        outdoor_air = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
        outdoor_air.setName(oa_name)

        # Set outdoor air per person
        oa_per_person = get_value_by_uuid(row, headers, oa_per_person_uuid)
        if !oa_per_person.nil?
          outdoor_air.setOutdoorAirFlowperPerson(oa_per_person.to_f)
        end

        # Set outdoor air per area
        oa_per_area = get_value_by_uuid(row, headers, oa_per_area_uuid)
        if !oa_per_area.nil?
          outdoor_air.setOutdoorAirFlowperFloorArea(oa_per_area.to_f)
        end

        # Set outdoor air changes per hour
        oa_ach = get_value_by_uuid(row, headers, oa_ach_uuid)
        if !oa_ach.nil?
          outdoor_air.setOutdoorAirFlowAirChangesperHour(oa_ach.to_f)
        end

        space_type.setDesignSpecificationOutdoorAir(outdoor_air)
        runner.registerInfo("  Created Outdoor Air: #{oa_name}")
      end

      # D. Create Electric Equipment Definition
      elec_name = get_value_by_uuid(row, headers, elec_name_uuid)
      if !elec_name.nil?
        elec_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        elec_def.setName(elec_name)

        # Set watts per area
        elec_watts = get_value_by_uuid(row, headers, elec_watts_per_area_uuid)
        if !elec_watts.nil?
          elec_def.setWattsperSpaceFloorArea(elec_watts.to_f)
        end

        # Set fractions
        elec_latent = get_value_by_uuid(row, headers, elec_fraction_latent_uuid)
        if !elec_latent.nil?
          elec_def.setFractionLatent(elec_latent.to_f)
        end

        elec_radiant = get_value_by_uuid(row, headers, elec_fraction_radiant_uuid)
        if !elec_radiant.nil?
          elec_def.setFractionRadiant(elec_radiant.to_f)
        end

        elec_lost = get_value_by_uuid(row, headers, elec_fraction_lost_uuid)
        if !elec_lost.nil?
          elec_def.setFractionLost(elec_lost.to_f)
        end

        # Create Electric Equipment instance
        elec_equip = OpenStudio::Model::ElectricEquipment.new(elec_def)
        elec_equip.setName("#{space_type_name}_ElecEquip")
        elec_equip.setSpaceType(space_type)

        # Get and create electric equipment schedule
        elec_sched_name = get_value_by_uuid(row, headers, elec_schedule_uuid)
        if !elec_sched_name.nil?
          elec_schedule = create_schedule_from_csv(model, runner, elec_sched_name, schedules_data, created_schedules)
          # Add to schedule set only (not to equipment object)
          if !elec_schedule.nil? && !schedule_set.nil?
            schedule_set.setElectricEquipmentSchedule(elec_schedule)
          end
        end

        runner.registerInfo("  Created Electric Equipment: #{elec_name}")
      end

      # E. Create Lights Definition
      lights_name = get_value_by_uuid(row, headers, lights_name_uuid)
      if !lights_name.nil?
        lights_def = OpenStudio::Model::LightsDefinition.new(model)
        lights_def.setName(lights_name)

        # Set watts per area
        lights_watts = get_value_by_uuid(row, headers, lights_watts_per_area_uuid)
        if !lights_watts.nil?
          lights_def.setWattsperSpaceFloorArea(lights_watts.to_f)
        end

        # Set fractions
        lights_radiant = get_value_by_uuid(row, headers, lights_fraction_radiant_uuid)
        if !lights_radiant.nil?
          lights_def.setFractionRadiant(lights_radiant.to_f)
        end

        lights_visible = get_value_by_uuid(row, headers, lights_fraction_visible_uuid)
        if !lights_visible.nil?
          lights_def.setFractionVisible(lights_visible.to_f)
        end

        # Create Lights instance
        lights = OpenStudio::Model::Lights.new(lights_def)
        lights.setName("#{space_type_name}_Lights")
        lights.setSpaceType(space_type)

        # Get and create lighting schedule
        lights_sched_name = get_value_by_uuid(row, headers, lights_schedule_uuid)
        if !lights_sched_name.nil?
          lights_schedule = create_schedule_from_csv(model, runner, lights_sched_name, schedules_data, created_schedules)
          # Add to schedule set only (not to lights object)
          if !lights_schedule.nil? && !schedule_set.nil?
            schedule_set.setLightingSchedule(lights_schedule)
          end
        end

        runner.registerInfo("  Created Lights: #{lights_name}")
      end

      # F. Create Gas Equipment Definition
      gas_name = get_value_by_uuid(row, headers, gas_name_uuid)
      if !gas_name.nil?
        gas_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
        gas_def.setName(gas_name)

        # Set power per area
        gas_power = get_value_by_uuid(row, headers, gas_power_per_area_uuid)
        if !gas_power.nil?
          gas_def.setWattsperSpaceFloorArea(gas_power.to_f)
        end

        # Set fractions
        gas_latent = get_value_by_uuid(row, headers, gas_fraction_latent_uuid)
        if !gas_latent.nil?
          gas_def.setFractionLatent(gas_latent.to_f)
        end

        gas_radiant = get_value_by_uuid(row, headers, gas_fraction_radiant_uuid)
        if !gas_radiant.nil?
          gas_def.setFractionRadiant(gas_radiant.to_f)
        end

        gas_lost = get_value_by_uuid(row, headers, gas_fraction_lost_uuid)
        if !gas_lost.nil?
          gas_def.setFractionLost(gas_lost.to_f)
        end

        # Create Gas Equipment instance
        gas_equip = OpenStudio::Model::GasEquipment.new(gas_def)
        gas_equip.setName("#{space_type_name}_GasEquip")
        gas_equip.setSpaceType(space_type)

        # Get and create gas equipment schedule
        gas_sched_name = get_value_by_uuid(row, headers, gas_schedule_uuid)
        if !gas_sched_name.nil?
          gas_schedule = create_schedule_from_csv(model, runner, gas_sched_name, schedules_data, created_schedules)
          # Add to schedule set only (not to equipment object)
          if !gas_schedule.nil? && !schedule_set.nil?
            schedule_set.setGasEquipmentSchedule(gas_schedule)
          end
        end

        runner.registerInfo("  Created Gas Equipment: #{gas_name}")
      end

      # G. Create Space Infiltration Design Flow Rate
      infil_name = get_value_by_uuid(row, headers, infil_name_uuid)
      if !infil_name.nil?
        infiltration = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        infiltration.setName(infil_name)

        # Set flow per exterior area
        infil_flow = get_value_by_uuid(row, headers, infil_flow_per_area_uuid)
        if !infil_flow.nil?
          infiltration.setFlowperExteriorSurfaceArea(infil_flow.to_f)
        end

        infiltration.setSpaceType(space_type)

        # Get and create infiltration schedule
        infil_sched_name = get_value_by_uuid(row, headers, infil_schedule_uuid)
        if !infil_sched_name.nil?
          infil_schedule = create_schedule_from_csv(model, runner, infil_sched_name, schedules_data, created_schedules)
          # Add to schedule set only (not to infiltration object)
          if !infil_schedule.nil? && !schedule_set.nil?
            schedule_set.setInfiltrationSchedule(infil_schedule)
          end
        end

        runner.registerInfo("  Created Infiltration: #{infil_name}")
      end

      space_types_created += 1
    end

    # Report final condition
    runner.registerFinalCondition("Created #{space_types_created} space types and #{created_schedules.size} schedules. Skipped #{rows_skipped} rows.")

    return true
  end
end

# register the measure to be used by the application
CreateCustomSpaceTypesFromCSV.new.registerWithApplication