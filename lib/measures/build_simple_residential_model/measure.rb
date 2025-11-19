# This measure was created by Helix Energy Partners LLC with Claude AI Sonnet 4.5 November 2025

require 'openstudio-standards'

#require_relative 'resources/Model.hvac' # DLM: should this be in openstudio-standards? dfg some tests fail without it

# start the measure
class BuildSimpleResidentialModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Build Simple Residential Model'
  end

  # human readable description
  def description
    return 'This measure creates a simple residential building model similar to ResStock/HPXML approach. It generates geometry, constructions, HVAC systems, and other building components for a single-family home.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure creates a residential model by defining geometry from high-level inputs (floor area, number of stories, etc.), applying residential constructions, adding HVAC and water heating systems, and configuring lighting and plug loads. The approach is similar to ResStock but simplified for demonstration purposes.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Delete existing model argument (first argument)
    delete_existing_model = OpenStudio::Measure::OSArgument.makeBoolArgument('delete_existing_model', true)
    delete_existing_model.setDisplayName('Delete Existing Model?')
    delete_existing_model.setDescription('If true, removes all existing objects from the model before creating the new residential building. If false, adds to the existing model.')
    delete_existing_model.setDefaultValue(true)
    args << delete_existing_model

    # Delete weather and design days argument (second argument)
    delete_weather_and_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('delete_weather_and_design_days', true)
    delete_weather_and_design_days.setDisplayName('Delete Existing Weather and Design Days?')
    delete_weather_and_design_days.setDescription('Only applies if Delete Existing Model is true. If false, preserves existing WeatherFile and DesignDay objects. If true, removes everything including weather data.')
    delete_weather_and_design_days.setDefaultValue(false)
    args << delete_weather_and_design_days

    # Geometry arguments
    chs = OpenStudio::StringVector.new
    chs << 'Single-Family Detached'
    chs << 'Single-Family Attached'
    chs << 'Apartment Unit'
    geometry_building_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('geometry_building_type', chs, true)
    geometry_building_type.setDisplayName('Building Type')
    geometry_building_type.setDefaultValue('Single-Family Detached')
    args << geometry_building_type

    geometry_cfa = OpenStudio::Measure::OSArgument.makeDoubleArgument('geometry_cfa', true)
    geometry_cfa.setDisplayName('Conditioned Floor Area')
    geometry_cfa.setUnits('ft^2')
    geometry_cfa.setDefaultValue(2000.0)
    args << geometry_cfa

    geometry_num_floors_above_grade = OpenStudio::Measure::OSArgument.makeIntegerArgument('geometry_num_floors_above_grade', true)
    geometry_num_floors_above_grade.setDisplayName('Number of Floors Above Grade')
    geometry_num_floors_above_grade.setDefaultValue(2)
    args << geometry_num_floors_above_grade

    geometry_aspect_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument('geometry_aspect_ratio', true)
    geometry_aspect_ratio.setDisplayName('Building Aspect Ratio')
    geometry_aspect_ratio.setDescription('Ratio of front wall length to side wall length')
    geometry_aspect_ratio.setDefaultValue(1.5)
    args << geometry_aspect_ratio

    # Foundation type
    chs = OpenStudio::StringVector.new
    chs << 'Slab'
    chs << 'Vented Crawlspace'
    chs << 'Unvented Crawlspace'
    chs << 'Conditioned Basement'
    foundation_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('foundation_type', chs, true)
    foundation_type.setDisplayName('Foundation Type')
    foundation_type.setDefaultValue('Slab')
    args << foundation_type

    # Envelope arguments
    wall_assembly_r = OpenStudio::Measure::OSArgument.makeDoubleArgument('wall_assembly_r', true)
    wall_assembly_r.setDisplayName('Wall Assembly R-value')
    wall_assembly_r.setUnits('h-ft^2-R/Btu')
    wall_assembly_r.setDefaultValue(13.0)
    args << wall_assembly_r

    ceiling_assembly_r = OpenStudio::Measure::OSArgument.makeDoubleArgument('ceiling_assembly_r', true)
    ceiling_assembly_r.setDisplayName('Ceiling/Attic Assembly R-value')
    ceiling_assembly_r.setUnits('h-ft^2-R/Btu')
    ceiling_assembly_r.setDefaultValue(38.0)
    args << ceiling_assembly_r

    window_ufactor = OpenStudio::Measure::OSArgument.makeDoubleArgument('window_ufactor', true)
    window_ufactor.setDisplayName('Window U-Factor')
    window_ufactor.setUnits('Btu/h-ft^2-R')
    window_ufactor.setDefaultValue(0.33)
    args << window_ufactor

    window_shgc = OpenStudio::Measure::OSArgument.makeDoubleArgument('window_shgc', true)
    window_shgc.setDisplayName('Window Solar Heat Gain Coefficient (SHGC)')
    window_shgc.setDefaultValue(0.45)
    args << window_shgc

    window_to_wall_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('window_to_wall_fraction', true)
    window_to_wall_fraction.setDisplayName('Window to Wall Ratio')
    window_to_wall_fraction.setDefaultValue(0.15)
    args << window_to_wall_fraction

    # HVAC arguments
    chs = OpenStudio::StringVector.new
    chs << 'Central Air Conditioner with Gas Furnace'
    chs << 'Central Air Conditioner with Electric Furnace'
    chs << 'Air Source Heat Pump'
    chs << 'Mini-Split Heat Pump'
    hvac_system_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('hvac_system_type', chs, true)
    hvac_system_type.setDisplayName('HVAC System Type')
    hvac_system_type.setDefaultValue('Central Air Conditioner with Gas Furnace')
    args << hvac_system_type

    hvac_cooling_efficiency_seer = OpenStudio::Measure::OSArgument.makeDoubleArgument('hvac_cooling_efficiency_seer', true)
    hvac_cooling_efficiency_seer.setDisplayName('Cooling System SEER')
    hvac_cooling_efficiency_seer.setUnits('Btu/W-h')
    hvac_cooling_efficiency_seer.setDefaultValue(13.0)
    args << hvac_cooling_efficiency_seer

    hvac_heating_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('hvac_heating_efficiency', true)
    hvac_heating_efficiency.setDisplayName('Heating System Efficiency (AFUE for furnace, HSPF for heat pump)')
    hvac_heating_efficiency.setDefaultValue(0.78)
    args << hvac_heating_efficiency

    # Domestic Hot Water arguments
    chs = OpenStudio::StringVector.new
    chs << 'Gas Storage Water Heater'
    chs << 'Electric Storage Water Heater'
    chs << 'Gas Tankless Water Heater'
    chs << 'Heat Pump Water Heater'
    dhw_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('dhw_type', chs, true)
    dhw_type.setDisplayName('Water Heater Type')
    dhw_type.setDefaultValue('Gas Storage Water Heater')
    args << dhw_type

    dhw_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('dhw_efficiency', true)
    dhw_efficiency.setDisplayName('Water Heater Energy Factor')
    dhw_efficiency.setDefaultValue(0.59)
    args << dhw_efficiency

    # Infiltration
    infiltration_ach50 = OpenStudio::Measure::OSArgument.makeDoubleArgument('infiltration_ach50', true)
    infiltration_ach50.setDisplayName('Air Leakage (ACH50)')
    infiltration_ach50.setUnits('1/h')
    infiltration_ach50.setDefaultValue(7.0)
    args << infiltration_ach50

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Get delete existing model argument
    delete_existing_model = runner.getBoolArgumentValue('delete_existing_model', user_arguments)
    delete_weather_and_design_days = runner.getBoolArgumentValue('delete_weather_and_design_days', user_arguments)
    
    # Delete existing model if requested
    if delete_existing_model
      if delete_weather_and_design_days
        # Delete EVERYTHING including weather and design days
        runner.registerInfo("Deleting all existing model objects including weather and design days...")
        
        # Get all object handles
        handles = OpenStudio::UUIDVector.new
        model.objects.each do |obj|
          handles << obj.handle
        end
        
        # Remove all objects
        model.removeObjects(handles)
        
        runner.registerInfo("All existing model objects deleted.")
      else
        # Delete everything EXCEPT weather and design days
        runner.registerInfo("Deleting all existing model objects except weather and design days...")
        
        # Get all object handles except WeatherFile and DesignDay objects
        handles = OpenStudio::UUIDVector.new
        model.objects.each do |obj|
          # Skip WeatherFile objects
          next if obj.to_WeatherFile.is_initialized
          
          # Skip DesignDay objects  
          next if obj.to_DesignDay.is_initialized
          
          # Delete everything else
          handles << obj.handle
        end
        
        # Remove selected objects
        model.removeObjects(handles)
        
        runner.registerInfo("Existing model objects deleted (preserved #{model.getDesignDays.size} design days and weather file). Creating new residential building model...")
      end
    else
      runner.registerInfo("Adding to existing model...")
    end

    # assign the user inputs to variables
    geometry_building_type = runner.getStringArgumentValue('geometry_building_type', user_arguments)
    geometry_cfa = runner.getDoubleArgumentValue('geometry_cfa', user_arguments)
    geometry_num_floors_above_grade = runner.getIntegerArgumentValue('geometry_num_floors_above_grade', user_arguments)
    geometry_aspect_ratio = runner.getDoubleArgumentValue('geometry_aspect_ratio', user_arguments)
    foundation_type = runner.getStringArgumentValue('foundation_type', user_arguments)
    wall_assembly_r = runner.getDoubleArgumentValue('wall_assembly_r', user_arguments)
    ceiling_assembly_r = runner.getDoubleArgumentValue('ceiling_assembly_r', user_arguments)
    window_ufactor = runner.getDoubleArgumentValue('window_ufactor', user_arguments)
    window_shgc = runner.getDoubleArgumentValue('window_shgc', user_arguments)
    window_to_wall_fraction = runner.getDoubleArgumentValue('window_to_wall_fraction', user_arguments)
    hvac_system_type = runner.getStringArgumentValue('hvac_system_type', user_arguments)
    hvac_cooling_efficiency_seer = runner.getDoubleArgumentValue('hvac_cooling_efficiency_seer', user_arguments)
    hvac_heating_efficiency = runner.getDoubleArgumentValue('hvac_heating_efficiency', user_arguments)
    dhw_type = runner.getStringArgumentValue('dhw_type', user_arguments)
    dhw_efficiency = runner.getDoubleArgumentValue('dhw_efficiency', user_arguments)
    infiltration_ach50 = runner.getDoubleArgumentValue('infiltration_ach50', user_arguments)

    # Convert units
    geometry_cfa_m2 = OpenStudio.convert(geometry_cfa, 'ft^2', 'm^2').get
    
    # Calculate geometry parameters
    floor_height = 2.7432  # 9 ft in meters
    total_floor_area = geometry_cfa_m2 / geometry_num_floors_above_grade
    width = Math.sqrt(total_floor_area / geometry_aspect_ratio)
    length = total_floor_area / width
    
    # Door dimensions (standard 3ft x 7ft)
    door_width = 0.9144   # 3 feet in meters
    door_height = 2.1336  # 7 feet in meters

    runner.registerInfo("Creating residential building with #{geometry_cfa} ft² CFA")
    runner.registerInfo("Building footprint: #{length.round(2)}m x #{width.round(2)}m")

    # Create schedules first (needed by multiple systems)
    schedules = create_residential_schedules(model, runner)

    # Create construction set first
    construction_set = create_construction_set(model, runner, wall_assembly_r, ceiling_assembly_r, window_ufactor, window_shgc, foundation_type)

    # Create space types with construction set
    space_types = create_space_types(model, runner, construction_set, schedules)

    # Create building geometry
    create_geometry(model, runner, length, width, floor_height, geometry_num_floors_above_grade, foundation_type, space_types)

    # Split door wall into 3 surfaces (left, middle for door, right)
    door_surface = split_wall_for_door(model, runner, door_width)

    # Add windows (will skip the door surface)
    add_windows(model, runner, window_to_wall_fraction, door_surface)

    # Add door to the pre-split middle surface
    add_door_to_surface(model, runner, door_surface, door_width) if door_surface

    # Add infiltration
    add_infiltration(model, runner, infiltration_ach50, geometry_cfa)

    # Add HVAC system
    add_hvac_system(model, runner, hvac_system_type, hvac_cooling_efficiency_seer, hvac_heating_efficiency)

    # Add domestic hot water system
    add_water_heater(model, runner, dhw_type, dhw_efficiency, schedules)

    # Add internal loads (lighting, plug loads, occupancy)
    add_internal_loads(model, runner, geometry_cfa)

    # Add thermostats
    add_thermostats(model, runner)

    runner.registerFinalCondition("Residential model created successfully with #{model.getSpaces.size} spaces")
    return true
  end

  # Create residential construction set
  def create_construction_set(model, runner, wall_r, ceiling_r, window_u, window_shgc, foundation_type)
    # Convert R-values to SI units
    wall_r_si = OpenStudio.convert(wall_r, 'ft^2*h*R/Btu', 'm^2*K/W').get
    ceiling_r_si = OpenStudio.convert(ceiling_r, 'ft^2*h*R/Btu', 'm^2*K/W').get
    window_u_si = OpenStudio.convert(window_u, 'Btu/ft^2*h*R', 'W/m^2*K').get

    # Create constructions
    wall_construction = create_simple_construction(model, 'Residential Wall Construction', wall_r_si, 'Wall')
    roof_construction = create_simple_construction(model, 'Residential Roof Construction', ceiling_r_si, 'RoofCeiling')
    floor_construction = create_simple_construction(model, 'Residential Floor Construction', 2.0, 'Floor')
    window_construction = create_window_construction(model, 'Residential Window Construction', window_u_si, window_shgc)
    door_construction = create_simple_construction(model, 'Residential Door Construction', 0.5, 'Wall')  # R-2.8 door

    # Create default construction set
    construction_set = OpenStudio::Model::DefaultConstructionSet.new(model)
    construction_set.setName('Residential Construction Set')

    # Create default surface constructions object for exterior surfaces
    exterior_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
    exterior_surface_constructions.setName('Residential Exterior Surface Constructions')
    exterior_surface_constructions.setWallConstruction(wall_construction)
    exterior_surface_constructions.setRoofCeilingConstruction(roof_construction)
    exterior_surface_constructions.setFloorConstruction(floor_construction)

    # Create default surface constructions object for interior surfaces
    interior_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
    interior_surface_constructions.setName('Residential Interior Surface Constructions')
    # For interior surfaces, use lighter constructions (could be customized)
    interior_wall_construction = create_simple_construction(model, 'Residential Interior Wall Construction', 1.0, 'Wall')
    interior_floor_construction = create_simple_construction(model, 'Residential Interior Floor Construction', 1.5, 'Floor')
    interior_surface_constructions.setWallConstruction(interior_wall_construction)
    interior_surface_constructions.setRoofCeilingConstruction(interior_floor_construction)  # Interior ceiling
    interior_surface_constructions.setFloorConstruction(interior_floor_construction)

    # Create default surface constructions object for ground contact surfaces
    ground_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
    ground_surface_constructions.setName('Residential Ground Surface Constructions')
    ground_surface_constructions.setFloorConstruction(floor_construction)

    # Create default subsurface constructions object (windows, doors, etc.)
    exterior_subsurface_constructions = OpenStudio::Model::DefaultSubSurfaceConstructions.new(model)
    exterior_subsurface_constructions.setName('Residential Exterior SubSurface Constructions')
    exterior_subsurface_constructions.setFixedWindowConstruction(window_construction)
    exterior_subsurface_constructions.setOperableWindowConstruction(window_construction)
    exterior_subsurface_constructions.setDoorConstruction(door_construction)
    exterior_subsurface_constructions.setGlassDoorConstruction(window_construction)
    exterior_subsurface_constructions.setOverheadDoorConstruction(door_construction)

    # Assign surface constructions to construction set
    construction_set.setDefaultExteriorSurfaceConstructions(exterior_surface_constructions)
    construction_set.setDefaultInteriorSurfaceConstructions(interior_surface_constructions)
    construction_set.setDefaultGroundContactSurfaceConstructions(ground_surface_constructions)
    construction_set.setDefaultExteriorSubSurfaceConstructions(exterior_subsurface_constructions)

    runner.registerInfo("Created Residential Construction Set with:")
    runner.registerInfo("  Wall R-value: #{wall_r} h-ft²-R/Btu")
    runner.registerInfo("  Roof R-value: #{ceiling_r} h-ft²-R/Btu")
    runner.registerInfo("  Window U-factor: #{window_u} Btu/h-ft²-R")
    runner.registerInfo("  Window SHGC: #{window_shgc}")

    return construction_set
  end

  # Create residential schedules
  def create_residential_schedules(model, runner)
    schedules = {}
    
    # Create Schedule Type Limits for different schedule types
    
    # Temperature schedule type limits (for degrees C)
    temp_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    temp_limits.setName('Temperature')
    temp_limits.setNumericType('Continuous')
    temp_limits.setUnitType('Temperature')
    
    # Fractional schedule type limits (0 to 1)
    fraction_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    fraction_limits.setName('Fractional')
    fraction_limits.setLowerLimitValue(0.0)
    fraction_limits.setUpperLimitValue(1.0)
    fraction_limits.setNumericType('Continuous')
    fraction_limits.setUnitType('Dimensionless')
    
    # On/Off schedule type limits (0 or 1)
    on_off_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    on_off_limits.setName('OnOff')
    on_off_limits.setLowerLimitValue(0.0)
    on_off_limits.setUpperLimitValue(1.0)
    on_off_limits.setNumericType('Discrete')
    on_off_limits.setUnitType('Dimensionless')
    
    # Activity level schedule type limits (W/person)
    activity_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    activity_limits.setName('ActivityLevel')
    activity_limits.setLowerLimitValue(0.0)
    activity_limits.setNumericType('Continuous')
    activity_limits.setUnitType('ActivityLevel')
    
    runner.registerInfo('Created Schedule Type Limits')
    
    # Create Always On schedule (for equipment that runs 24/7)
    always_on = model.alwaysOnDiscreteSchedule
    schedules[:always_on] = always_on
    
    # Create Occupancy Schedule (residential pattern)
    # Higher occupancy in evenings/nights and weekends
    occupancy_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    occupancy_sch.setName('Residential Occupancy Schedule')
    occupancy_sch.setScheduleTypeLimits(fraction_limits)
    
    # Default day schedule (weekday pattern)
    occupancy_default = occupancy_sch.defaultDaySchedule
    occupancy_default.setName('Residential Occupancy Default')
    occupancy_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 1.0)   # Midnight-6am: 100% (sleeping)
    occupancy_default.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.5)   # 6am-8am: 50% (morning routine)
    occupancy_default.addValue(OpenStudio::Time.new(0, 17, 0, 0), 0.3)  # 8am-5pm: 30% (some away at work)
    occupancy_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.9)  # 5pm-10pm: 90% (evening home)
    occupancy_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1.0)  # 10pm-midnight: 100% (sleeping)
    
    # Weekend rule (higher occupancy during day)
    occupancy_weekend_rule = OpenStudio::Model::ScheduleRule.new(occupancy_sch)
    occupancy_weekend_rule.setName('Residential Occupancy Weekend')
    occupancy_weekend_rule.setApplySaturday(true)
    occupancy_weekend_rule.setApplySunday(true)
    occupancy_weekend_day = occupancy_weekend_rule.daySchedule
    occupancy_weekend_day.addValue(OpenStudio::Time.new(0, 8, 0, 0), 1.0)   # Midnight-8am: 100%
    occupancy_weekend_day.addValue(OpenStudio::Time.new(0, 20, 0, 0), 0.9)  # 8am-8pm: 90%
    occupancy_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1.0)  # 8pm-midnight: 100%
    
    schedules[:occupancy] = occupancy_sch
    runner.registerInfo('Created Residential Occupancy Schedule')
    
    # Create Lighting Schedule (residential pattern)
    # Higher use in evenings, lower during day
    lighting_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    lighting_sch.setName('Residential Lighting Schedule')
    lighting_sch.setScheduleTypeLimits(fraction_limits)
    
    lighting_default = lighting_sch.defaultDaySchedule
    lighting_default.setName('Residential Lighting Default')
    lighting_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 0.1)   # Midnight-6am: 10%
    lighting_default.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.3)   # 6am-8am: 30%
    lighting_default.addValue(OpenStudio::Time.new(0, 16, 0, 0), 0.2)  # 8am-4pm: 20%
    lighting_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.7)  # 4pm-10pm: 70% (peak evening)
    lighting_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.2)  # 10pm-midnight: 20%
    
    # Weekend lighting (similar but slightly different)
    lighting_weekend_rule = OpenStudio::Model::ScheduleRule.new(lighting_sch)
    lighting_weekend_rule.setName('Residential Lighting Weekend')
    lighting_weekend_rule.setApplySaturday(true)
    lighting_weekend_rule.setApplySunday(true)
    lighting_weekend_day = lighting_weekend_rule.daySchedule
    lighting_weekend_day.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.1)   # Midnight-8am: 10%
    lighting_weekend_day.addValue(OpenStudio::Time.new(0, 18, 0, 0), 0.3)  # 8am-6pm: 30%
    lighting_weekend_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.6)  # 6pm-10pm: 60%
    lighting_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.2)  # 10pm-midnight: 20%
    
    schedules[:lighting] = lighting_sch
    runner.registerInfo('Created Residential Lighting Schedule')
    
    # Create Electric Equipment Schedule (plug loads - fairly constant with evening peak)
    equipment_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    equipment_sch.setName('Residential Equipment Schedule')
    equipment_sch.setScheduleTypeLimits(fraction_limits)
    
    equipment_default = equipment_sch.defaultDaySchedule
    equipment_default.setName('Residential Equipment Default')
    equipment_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 0.5)   # Midnight-6am: 50%
    equipment_default.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.6)   # 6am-8am: 60%
    equipment_default.addValue(OpenStudio::Time.new(0, 17, 0, 0), 0.5)  # 8am-5pm: 50%
    equipment_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.8)  # 5pm-10pm: 80% (peak)
    equipment_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.6)  # 10pm-midnight: 60%
    
    # Weekend equipment (slightly higher use)
    equipment_weekend_rule = OpenStudio::Model::ScheduleRule.new(equipment_sch)
    equipment_weekend_rule.setName('Residential Equipment Weekend')
    equipment_weekend_rule.setApplySaturday(true)
    equipment_weekend_rule.setApplySunday(true)
    equipment_weekend_day = equipment_weekend_rule.daySchedule
    equipment_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.7)  # All day: 70%
    
    schedules[:equipment] = equipment_sch
    runner.registerInfo('Created Residential Equipment Schedule')
    
    # Create Activity Level Schedule (for people - W/person)
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    activity_sch.setName('Residential Activity Schedule')
    activity_sch.setScheduleTypeLimits(activity_limits)
    
    activity_default = activity_sch.defaultDaySchedule
    activity_default.setName('Residential Activity Default')
    activity_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 72.0)   # Sleeping: 72 W/person
    activity_default.addValue(OpenStudio::Time.new(0, 8, 0, 0), 120.0)  # Morning routine: 120 W/person
    activity_default.addValue(OpenStudio::Time.new(0, 18, 0, 0), 100.0) # Day activities: 100 W/person
    activity_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 120.0) # Evening: 120 W/person
    activity_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 72.0)  # Sleeping: 72 W/person
    
    schedules[:activity] = activity_sch
    runner.registerInfo('Created Residential Activity Schedule')
    
    # Create Infiltration Schedule (typically constant, slight reduction when HVAC operating)
    infiltration_sch = OpenStudio::Model::ScheduleConstant.new(model)
    infiltration_sch.setName('Residential Infiltration Schedule')
    infiltration_sch.setScheduleTypeLimits(fraction_limits)
    infiltration_sch.setValue(1.0)
    
    schedules[:infiltration] = infiltration_sch
    runner.registerInfo('Created Residential Infiltration Schedule')
    
    # Create Ambient Temperature Schedule (for water heater ambient conditions)
    ambient_temp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    ambient_temp_sch.setName('Ambient Temperature Schedule')
    ambient_temp_sch.setScheduleTypeLimits(temp_limits)
    ambient_temp_sch.setValue(22.0)  # 22°C (71.6°F) - typical conditioned space temperature
    
    schedules[:ambient_temp] = ambient_temp_sch
    runner.registerInfo('Created Ambient Temperature Schedule')
    
    # Create Water Heater Setpoint Temperature Schedule
    wh_setpoint_sch = OpenStudio::Model::ScheduleConstant.new(model)
    wh_setpoint_sch.setName('Water Heater Setpoint Temperature Schedule')
    wh_setpoint_sch.setScheduleTypeLimits(temp_limits)
    wh_setpoint_sch.setValue(60.0)  # 60°C (140°F) - typical residential water heater setpoint
    
    schedules[:wh_setpoint] = wh_setpoint_sch
    runner.registerInfo('Created Water Heater Setpoint Temperature Schedule')
    
    # Create Hot Water Flow Rate Schedule (residential usage pattern)
    hw_flow_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    hw_flow_sch.setName('Residential Hot Water Flow Rate Schedule')
    hw_flow_sch.setScheduleTypeLimits(fraction_limits)
    
    hw_flow_default = hw_flow_sch.defaultDaySchedule
    hw_flow_default.setName('Residential Hot Water Flow Rate Default')
    hw_flow_default.addValue(OpenStudio::Time.new(0, 5, 0, 0), 0.0)    # Midnight-5am: 0%
    hw_flow_default.addValue(OpenStudio::Time.new(0, 7, 0, 0), 0.3)    # 5am-7am: 30% (morning)
    hw_flow_default.addValue(OpenStudio::Time.new(0, 9, 0, 0), 0.5)    # 7am-9am: 50% (peak morning)
    hw_flow_default.addValue(OpenStudio::Time.new(0, 17, 0, 0), 0.1)   # 9am-5pm: 10% (low daytime)
    hw_flow_default.addValue(OpenStudio::Time.new(0, 21, 0, 0), 0.4)   # 5pm-9pm: 40% (evening)
    hw_flow_default.addValue(OpenStudio::Time.new(0, 23, 0, 0), 0.2)   # 9pm-11pm: 20%
    hw_flow_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.0)   # 11pm-midnight: 0%
    
    # Weekend hot water use (more distributed throughout day)
    hw_flow_weekend_rule = OpenStudio::Model::ScheduleRule.new(hw_flow_sch)
    hw_flow_weekend_rule.setName('Residential Hot Water Flow Rate Weekend')
    hw_flow_weekend_rule.setApplySaturday(true)
    hw_flow_weekend_rule.setApplySunday(true)
    hw_flow_weekend_day = hw_flow_weekend_rule.daySchedule
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 7, 0, 0), 0.0)    # Midnight-7am: 0%
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 10, 0, 0), 0.4)   # 7am-10am: 40%
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 12, 0, 0), 0.3)   # 10am-noon: 30%
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 18, 0, 0), 0.2)   # Noon-6pm: 20%
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.3)   # 6pm-10pm: 30%
    hw_flow_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.1)   # 10pm-midnight: 10%
    
    schedules[:hw_flow] = hw_flow_sch
    runner.registerInfo('Created Residential Hot Water Flow Rate Schedule')
    
    # Create Hot Water Target Temperature Schedule
    hw_temp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    hw_temp_sch.setName('Residential Hot Water Target Temperature Schedule')
    hw_temp_sch.setScheduleTypeLimits(temp_limits)
    hw_temp_sch.setValue(43.3)  # 43.3°C (110°F) - typical mixed hot water delivery temperature
    
    schedules[:hw_temp] = hw_temp_sch
    runner.registerInfo('Created Residential Hot Water Target Temperature Schedule')
    
    return schedules
  end

  # Create residential space types
  def create_space_types(model, runner, construction_set, schedules)
    space_types = {}

    # Create Living Space Type (for above-grade conditioned spaces)
    living_space_type = OpenStudio::Model::SpaceType.new(model)
    living_space_type.setName('Residential - Living Space')
    living_space_type.setStandardsSpaceType('Living Space')
    living_space_type.setStandardsBuildingType('Residential')
    
    # Assign construction set to space type
    living_space_type.setDefaultConstructionSet(construction_set)
    
    # Create and assign schedule set for living space
    living_schedule_set = OpenStudio::Model::DefaultScheduleSet.new(model)
    living_schedule_set.setName('Residential Living Schedule Set')
    living_schedule_set.setNumberofPeopleSchedule(schedules[:occupancy])
    living_schedule_set.setPeopleActivityLevelSchedule(schedules[:activity])
    living_schedule_set.setLightingSchedule(schedules[:lighting])
    living_schedule_set.setElectricEquipmentSchedule(schedules[:equipment])
    living_schedule_set.setInfiltrationSchedule(schedules[:infiltration])
    living_space_type.setDefaultScheduleSet(living_schedule_set)
    
    # Set design specification for outdoor air
    oa_spec = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
    oa_spec.setName('Residential Living OA')
    oa_spec.setOutdoorAirMethod('Sum')
    oa_spec.setOutdoorAirFlowperPerson(0.00944)  # 20 cfm/person = 0.00944 m³/s/person
    oa_spec.setOutdoorAirFlowperFloorArea(0.0)
    living_space_type.setDesignSpecificationOutdoorAir(oa_spec)
    
    # Add Lighting to Living Space Type (residential: ~1.5 W/ft² = 16 W/m²)
    lights_def = OpenStudio::Model::LightsDefinition.new(model)
    lights_def.setName('Residential Living Lights Definition')
    lights_def.setWattsperSpaceFloorArea(16.0)
    
    lights = OpenStudio::Model::Lights.new(lights_def)
    lights.setName('Residential Living Lights')
    lights.setSpaceType(living_space_type)
    lights.setSchedule(schedules[:lighting])
    
    # Add Electric Equipment to Living Space Type (residential: ~0.8 W/ft² = 8.6 W/m²)
    plugload_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    plugload_def.setName('Residential Living Plug Loads Definition')
    plugload_def.setWattsperSpaceFloorArea(8.6)
    
    plugload = OpenStudio::Model::ElectricEquipment.new(plugload_def)
    plugload.setName('Residential Living Plug Loads')
    plugload.setSpaceType(living_space_type)
    plugload.setSchedule(schedules[:equipment])
    
    # Add People to Living Space Type (residential: 2.5 people per 100 m² = 0.025 people/m²)
    people_def = OpenStudio::Model::PeopleDefinition.new(model)
    people_def.setName('Residential Living Occupants Definition')
    people_def.setPeopleperSpaceFloorArea(0.025)
    
    people = OpenStudio::Model::People.new(people_def)
    people.setName('Residential Living Occupants')
    people.setSpaceType(living_space_type)
    people.setNumberofPeopleSchedule(schedules[:occupancy])
    people.setActivityLevelSchedule(schedules[:activity])
    
    # Add Space Infiltration Design Flow Rate to Living Space Type
    # Note: The actual ACH value will be set when add_infiltration is called
    # This creates the infiltration object that will be inherited by spaces
    infiltration_living = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infiltration_living.setName('Residential Living Infiltration')
    infiltration_living.setSpaceType(living_space_type)
    infiltration_living.setSchedule(schedules[:infiltration])
    # Air changes per hour will be set in add_infiltration method based on user input
    
    space_types[:living] = living_space_type
    runner.registerInfo("Created space type: Residential - Living Space (with construction set, loads, infiltration, and schedules)")

    # Create Basement Space Type (for conditioned basement)
    basement_space_type = OpenStudio::Model::SpaceType.new(model)
    basement_space_type.setName('Residential - Basement')
    basement_space_type.setStandardsSpaceType('Basement')
    basement_space_type.setStandardsBuildingType('Residential')
    
    # Assign construction set to space type
    basement_space_type.setDefaultConstructionSet(construction_set)
    
    # Create and assign schedule set for basement (same schedules, but could be different)
    basement_schedule_set = OpenStudio::Model::DefaultScheduleSet.new(model)
    basement_schedule_set.setName('Residential Basement Schedule Set')
    basement_schedule_set.setNumberofPeopleSchedule(schedules[:occupancy])
    basement_schedule_set.setPeopleActivityLevelSchedule(schedules[:activity])
    basement_schedule_set.setLightingSchedule(schedules[:lighting])
    basement_schedule_set.setElectricEquipmentSchedule(schedules[:equipment])
    basement_schedule_set.setInfiltrationSchedule(schedules[:infiltration])
    basement_space_type.setDefaultScheduleSet(basement_schedule_set)
    
    # Basement typically has lower occupancy and loads
    oa_spec_basement = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
    oa_spec_basement.setName('Residential Basement OA')
    oa_spec_basement.setOutdoorAirMethod('Sum')
    oa_spec_basement.setOutdoorAirFlowperPerson(0.00944)  # 20 cfm/person
    oa_spec_basement.setOutdoorAirFlowperFloorArea(0.0)
    basement_space_type.setDesignSpecificationOutdoorAir(oa_spec_basement)
    
    # Add Lighting to Basement Space Type (lower than living: ~1.0 W/ft² = 10.8 W/m²)
    lights_def_basement = OpenStudio::Model::LightsDefinition.new(model)
    lights_def_basement.setName('Residential Basement Lights Definition')
    lights_def_basement.setWattsperSpaceFloorArea(10.8)
    
    lights_basement = OpenStudio::Model::Lights.new(lights_def_basement)
    lights_basement.setName('Residential Basement Lights')
    lights_basement.setSpaceType(basement_space_type)
    lights_basement.setSchedule(schedules[:lighting])
    
    # Add Electric Equipment to Basement Space Type (lower: ~0.5 W/ft² = 5.4 W/m²)
    plugload_def_basement = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    plugload_def_basement.setName('Residential Basement Plug Loads Definition')
    plugload_def_basement.setWattsperSpaceFloorArea(5.4)
    
    plugload_basement = OpenStudio::Model::ElectricEquipment.new(plugload_def_basement)
    plugload_basement.setName('Residential Basement Plug Loads')
    plugload_basement.setSpaceType(basement_space_type)
    plugload_basement.setSchedule(schedules[:equipment])
    
    # Add People to Basement Space Type (lower occupancy: 1.5 people per 100 m² = 0.015 people/m²)
    people_def_basement = OpenStudio::Model::PeopleDefinition.new(model)
    people_def_basement.setName('Residential Basement Occupants Definition')
    people_def_basement.setPeopleperSpaceFloorArea(0.015)
    
    people_basement = OpenStudio::Model::People.new(people_def_basement)
    people_basement.setName('Residential Basement Occupants')
    people_basement.setSpaceType(basement_space_type)
    people_basement.setNumberofPeopleSchedule(schedules[:occupancy])
    people_basement.setActivityLevelSchedule(schedules[:activity])
    
    # Add Space Infiltration Design Flow Rate to Basement Space Type
    infiltration_basement = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infiltration_basement.setName('Residential Basement Infiltration')
    infiltration_basement.setSpaceType(basement_space_type)
    infiltration_basement.setSchedule(schedules[:infiltration])
    # Air changes per hour will be set in add_infiltration method based on user input
    
    space_types[:basement] = basement_space_type
    runner.registerInfo("Created space type: Residential - Basement (with construction set, loads, infiltration, and schedules)")

    return space_types
  end

  # Create building geometry
  def create_geometry(model, runner, length, width, floor_height, num_floors, foundation_type, space_types)
    # Use "storey" nomenclature for consistency with building terminology
    num_storeys = num_floors
    
    # Create BuildingStory objects for each floor
    building_storeys = []
    
    # Create basement storey if needed
    if foundation_type == 'Conditioned Basement'
      basement_storey = OpenStudio::Model::BuildingStory.new(model)
      basement_storey.setName("Basement")
      basement_storey.setNominalZCoordinate(-floor_height)
      building_storeys << basement_storey
      runner.registerInfo("Created BuildingStory: Basement at nominal z = #{(-floor_height).round(2)}m")
    end
    
    # Create above-grade storeys
    num_storeys.times do |storey_num|
      storey = OpenStudio::Model::BuildingStory.new(model)
      storey.setName("Storey_#{storey_num + 1}")
      storey.setNominalZCoordinate(storey_num * floor_height)
      building_storeys << storey
      runner.registerInfo("Created BuildingStory: Storey_#{storey_num + 1} at nominal z = #{(storey_num * floor_height).round(2)}m")
    end
    
    # Create spaces for each storey
    # All spaces use z-origin = 0 (relative to their storey)
    # The BuildingStory nominalZCoordinate defines the storey elevation
    num_storeys.times do |storey_num|
      # Calculate absolute z-coordinate for geometry creation
      z_absolute = storey_num * floor_height
      
      # Create floor polygon at absolute z-coordinate for proper geometry
      polygon = []
      polygon << OpenStudio::Point3d.new(0, 0, z_absolute)
      polygon << OpenStudio::Point3d.new(0, width, z_absolute)
      polygon << OpenStudio::Point3d.new(length, width, z_absolute)
      polygon << OpenStudio::Point3d.new(length, 0, z_absolute)

      # Create space from polygon
      space = OpenStudio::Model::Space.fromFloorPrint(polygon, floor_height, model)
      if space.empty?
        runner.registerError("Could not create space for storey #{storey_num + 1}")
        return false
      end
      space = space.get
      space.setName("Floor_#{storey_num + 1}")
      
      # Set space origin to 0 (relative to storey, not absolute)
      # The BuildingStory nominalZCoordinate handles the absolute elevation
      space.setXOrigin(0)
      space.setYOrigin(0)
      space.setZOrigin(0)
      
      # Assign space to building storey
      storey_index = (foundation_type == 'Conditioned Basement') ? storey_num + 1 : storey_num
      space.setBuildingStory(building_storeys[storey_index])
      
      # Assign space type to living space
      space.setSpaceType(space_types[:living])

      # Create thermal zone
      zone = OpenStudio::Model::ThermalZone.new(model)
      zone.setName("Floor_#{storey_num + 1}_Zone")
      space.setThermalZone(zone)

      runner.registerInfo("Created space: #{space.name} in zone: #{zone.name} at absolute z = #{z_absolute.round(2)}m, space z-origin = 0, assigned to #{building_storeys[storey_index].name}")
    end

    # Handle foundation space if needed
    if foundation_type == 'Conditioned Basement'
      z_absolute = -floor_height
      
      # Create basement polygon at absolute z-coordinate
      polygon = []
      polygon << OpenStudio::Point3d.new(0, 0, z_absolute)
      polygon << OpenStudio::Point3d.new(0, width, z_absolute)
      polygon << OpenStudio::Point3d.new(length, width, z_absolute)
      polygon << OpenStudio::Point3d.new(length, 0, z_absolute)

      space = OpenStudio::Model::Space.fromFloorPrint(polygon, floor_height, model)
      if space.empty?
        runner.registerError("Could not create basement space")
        return false
      end
      space = space.get
      space.setName("Basement")
      
      # Set space origin to 0 (relative to basement storey)
      space.setXOrigin(0)
      space.setYOrigin(0)
      space.setZOrigin(0)
      
      # Assign to basement storey
      space.setBuildingStory(building_storeys[0])
      
      # Assign basement space type
      space.setSpaceType(space_types[:basement])

      zone = OpenStudio::Model::ThermalZone.new(model)
      zone.setName("Basement_Zone")
      space.setThermalZone(zone)

      runner.registerInfo("Created conditioned basement space at absolute z = #{z_absolute.round(2)}m, space z-origin = 0, assigned to Basement storey")
    end

    return true
  end

  # Create simplified construction
  def create_simple_construction(model, name, r_value, surface_type)
    construction = OpenStudio::Model::Construction.new(model)
    construction.setName(name)

    # Create material with target R-value
    material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material.setName("#{name} Material")
    material.setRoughness('MediumRough')
    material.setThickness(0.1)  # 10 cm
    
    # Calculate conductivity for target R-value
    conductivity = 0.1 / r_value
    material.setThermalConductivity(conductivity)
    material.setDensity(800)
    material.setSpecificHeat(1000)

    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    construction.setLayers(layers)

    return construction
  end

  # Create window construction
  def create_window_construction(model, name, u_factor, shgc)
    construction = OpenStudio::Model::Construction.new(model)
    construction.setName(name)

    # Create simple glazing
    glazing = OpenStudio::Model::SimpleGlazing.new(model)
    glazing.setName("#{name} Glazing")
    glazing.setUFactor(u_factor)
    glazing.setSolarHeatGainCoefficient(shgc)

    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    construction.setLayers(layers)

    return construction
  end

  # Split a wall into 3 surfaces for door placement
  def split_wall_for_door(model, runner, door_width)
    # Find a suitable first-floor exterior wall for the door
    suitable_surfaces = []
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType == 'Wall' && surface.outsideBoundaryCondition == 'Outdoors'
      next if surface.space.empty?
      
      space = surface.space.get
      
      # Check if this is a first floor surface by looking at vertex z-coordinates
      # First floor surfaces will have vertices near z=0
      vertices = surface.vertices
      next if vertices.size != 4
      
      # Get minimum z-coordinate of surface vertices
      z_coords = vertices.map { |v| v.z }
      min_z = z_coords.min
      
      # Check if surface is on first floor (minimum z near 0)
      # Allow small tolerance for slab vs crawlspace
      if min_z > 0.5
        runner.registerInfo("Skipping #{surface.name} - surface min z = #{min_z.round(2)}m (not first floor)")
        next
      end
      
      # Need wall wide enough for door plus two window sections
      # Middle section will be 2x door width, need enough for side sections too
      min_width = door_width * 2.0 + 2.0  # 2x door + 1m on each side minimum
      
      wall_width = (vertices[1] - vertices[0]).length
      if wall_width < min_width
        runner.registerInfo("Skipping #{surface.name} - too narrow (#{wall_width.round(2)}m < #{min_width.round(2)}m)")
        next
      end
      
      runner.registerInfo("Found suitable first floor wall: #{surface.name} (min z = #{min_z.round(2)}m, width = #{wall_width.round(2)}m)")
      suitable_surfaces << surface
    end
    
    if suitable_surfaces.empty?
      runner.registerWarning("No suitable wall found for door (need first floor exterior wall ≥ #{(door_width * 2.0 + 2.0).round(2)}m wide)")
      return nil
    end
    
    # Use the first suitable surface
    original_surface = suitable_surfaces.first
    space = original_surface.space.get
    
    runner.registerInfo("Splitting wall #{original_surface.name} (space: #{space.name}) into 3 sections for door placement")
    
    # Get original surface properties
    vertices = original_surface.vertices
    construction = original_surface.construction
    
    # Find the bottom two vertices (minimum z-coordinates)
    z_coords = vertices.map { |v| v.z }
    min_z = z_coords.min
    bottom_vertices = vertices.select { |v| (v.z - min_z).abs < 0.01 }
    top_vertices = vertices.select { |v| (v.z - min_z).abs >= 0.01 }
    
    # Order bottom vertices left to right by x-coordinate primarily
    if bottom_vertices.size == 2
      if bottom_vertices[0].x > bottom_vertices[1].x
        bottom_vertices.reverse!
      elsif (bottom_vertices[0].x - bottom_vertices[1].x).abs < 0.01
        # If x-coordinates are the same, sort by y
        if bottom_vertices[0].y > bottom_vertices[1].y
          bottom_vertices.reverse!
        end
      end
    end
    
    # Order top vertices left to right
    if top_vertices.size == 2
      if top_vertices[0].x > top_vertices[1].x
        top_vertices.reverse!
      elsif (top_vertices[0].x - top_vertices[1].x).abs < 0.01
        if top_vertices[0].y > top_vertices[1].y
          top_vertices.reverse!
        end
      end
    end
    
    v_bottom_left = bottom_vertices[0]
    v_bottom_right = bottom_vertices[1]
    v_top_left = top_vertices[0]
    v_top_right = top_vertices[1]
    
    # Calculate wall width and height
    wall_vector = v_bottom_right - v_bottom_left
    wall_width = wall_vector.length
    wall_height = (v_top_left - v_bottom_left).length
    
    # Calculate section widths
    middle_section_width = door_width * 2.0  # Middle section is 2x door width
    side_section_width = (wall_width - middle_section_width) / 2.0
    
    # Create unit vector along wall
    wall_unit = OpenStudio::Vector3d.new(wall_vector.x / wall_width,
                                          wall_vector.y / wall_width,
                                          wall_vector.z / wall_width)
    
    # Create unit vector up wall
    up_vector = v_top_left - v_bottom_left
    up_unit = OpenStudio::Vector3d.new(up_vector.x / wall_height,
                                        up_vector.y / wall_height,
                                        up_vector.z / wall_height)
    
    # Calculate split points along bottom and top
    left_split_vec = OpenStudio::Vector3d.new(wall_unit.x * side_section_width,
                                               wall_unit.y * side_section_width,
                                               wall_unit.z * side_section_width)
    right_split_vec = OpenStudio::Vector3d.new(wall_unit.x * (side_section_width + middle_section_width),
                                                wall_unit.y * (side_section_width + middle_section_width),
                                                wall_unit.z * (side_section_width + middle_section_width))
    
    # Bottom split points
    bottom_left_split = v_bottom_left + left_split_vec
    bottom_right_split = v_bottom_left + right_split_vec
    
    # Top split points  
    top_left_split = v_top_left + left_split_vec
    top_right_split = v_top_left + right_split_vec
    
    # Get the original surface's outward normal to preserve orientation
    original_outward_normal = original_surface.outwardNormal
    
    # Create three new surfaces
    # Left surface
    left_vertices = OpenStudio::Point3dVector.new
    left_vertices << v_bottom_left
    left_vertices << bottom_left_split
    left_vertices << top_left_split
    left_vertices << v_top_left
    
    left_surface = OpenStudio::Model::Surface.new(left_vertices, model)
    left_surface.setName("#{original_surface.name}_Left")
    left_surface.setSurfaceType('Wall')
    left_surface.setOutsideBoundaryCondition('Outdoors')
    left_surface.setSpace(space)
    left_surface.setConstruction(construction.get) if !construction.empty?
    
    # Check if left surface normal matches original - if not, reverse vertices
    if left_surface.outwardNormal.dot(original_outward_normal) < 0
      reversed_vertices = OpenStudio::Point3dVector.new
      (left_vertices.size - 1).downto(0) do |i|
        reversed_vertices << left_vertices[i]
      end
      left_surface.setVertices(reversed_vertices)
      runner.registerInfo("Reversed left surface vertices to match original orientation")
    end
    
    # Middle surface (for door)
    middle_vertices = OpenStudio::Point3dVector.new
    middle_vertices << bottom_left_split
    middle_vertices << bottom_right_split
    middle_vertices << top_right_split
    middle_vertices << top_left_split
    
    middle_surface = OpenStudio::Model::Surface.new(middle_vertices, model)
    middle_surface.setName("#{original_surface.name}_Door")
    middle_surface.setSurfaceType('Wall')
    middle_surface.setOutsideBoundaryCondition('Outdoors')
    middle_surface.setSpace(space)
    middle_surface.setConstruction(construction.get) if !construction.empty?
    
    # Check if middle surface normal matches original - if not, reverse vertices
    if middle_surface.outwardNormal.dot(original_outward_normal) < 0
      reversed_vertices = OpenStudio::Point3dVector.new
      (middle_vertices.size - 1).downto(0) do |i|
        reversed_vertices << middle_vertices[i]
      end
      middle_surface.setVertices(reversed_vertices)
      runner.registerInfo("Reversed middle surface vertices to match original orientation")
    end
    
    # Right surface
    right_vertices = OpenStudio::Point3dVector.new
    right_vertices << bottom_right_split
    right_vertices << v_bottom_right
    right_vertices << v_top_right
    right_vertices << top_right_split
    
    right_surface = OpenStudio::Model::Surface.new(right_vertices, model)
    right_surface.setName("#{original_surface.name}_Right")
    right_surface.setSurfaceType('Wall')
    right_surface.setOutsideBoundaryCondition('Outdoors')
    right_surface.setSpace(space)
    right_surface.setConstruction(construction.get) if !construction.empty?
    
    # Check if right surface normal matches original - if not, reverse vertices
    if right_surface.outwardNormal.dot(original_outward_normal) < 0
      reversed_vertices = OpenStudio::Point3dVector.new
      (right_vertices.size - 1).downto(0) do |i|
        reversed_vertices << right_vertices[i]
      end
      right_surface.setVertices(reversed_vertices)
      runner.registerInfo("Reversed right surface vertices to match original orientation")
    end
    
    # Remove original surface
    original_surface.remove
    
    runner.registerInfo("Split wall into 3 sections: Left (#{side_section_width.round(2)}m), Middle/Door (#{middle_section_width.round(2)}m), Right (#{side_section_width.round(2)}m)")
    
    return middle_surface
  end

  # Add windows to exterior walls
  def add_windows(model, runner, window_to_wall_fraction, door_surface = nil)
    # Get window construction from the default construction set
    window_construction = nil
    model.getSpaceTypes.each do |space_type|
      construction_set = space_type.defaultConstructionSet
      if !construction_set.empty?
        subsurface_constructions = construction_set.get.defaultExteriorSubSurfaceConstructions
        if !subsurface_constructions.empty?
          window_construction = subsurface_constructions.get.fixedWindowConstruction
          break if !window_construction.empty?
        end
      end
    end
    
    if window_construction.nil? || window_construction.empty?
      runner.registerWarning("Window construction not found in construction set, windows may use default construction")
    else
      window_construction = window_construction.get
    end
    
    windows_added = 0
    model.getSurfaces.each do |surface|
      next unless surface.surfaceType == 'Wall' && surface.outsideBoundaryCondition == 'Outdoors'
      
      # Skip the door surface (middle section)
      next if door_surface && surface.handle.to_s == door_surface.handle.to_s
      
      # Skip very small walls
      next if surface.grossArea < 1.0  # Skip walls smaller than 1 m²
      
      # Use the setWindowToWallRatio method
      # Parameters: ratio, sill height offset (meters), heightOffsetFromFloor (boolean)
      # The boolean indicates if offset is from floor (true) or from top (false)
      # Using 0.9m sill height from floor (about 3 feet)
      sub_surface = surface.setWindowToWallRatio(window_to_wall_fraction, 0.9, true)
      
      if sub_surface.empty?
        runner.registerWarning("Could not create window on surface #{surface.name} (area: #{surface.grossArea.round(2)} m²)")
      else
        # Set window construction if we found one
        if !window_construction.nil?
          sub_surface.get.setConstruction(window_construction)
        end
        windows_added += 1
        runner.registerInfo("Added window to #{surface.name} (#{(surface.grossArea * window_to_wall_fraction).round(2)} m²)")
      end
    end

    if windows_added == 0
      runner.registerWarning("No windows were created. Check geometry and WWR value (#{(window_to_wall_fraction * 100).round(1)}%)")
    else
      runner.registerInfo("Successfully added #{windows_added} windows with #{(window_to_wall_fraction * 100).round(1)}% window-to-wall ratio")
    end
    
    return true
  end

  # Add door to exterior wall
  # Add door to pre-split door surface
  def add_door_to_surface(model, runner, door_surface, door_width)
    # Get door construction from the default construction set
    door_construction = nil
    model.getSpaceTypes.each do |space_type|
      construction_set = space_type.defaultConstructionSet
      if !construction_set.empty?
        subsurface_constructions = construction_set.get.defaultExteriorSubSurfaceConstructions
        if !subsurface_constructions.empty?
          door_construction = subsurface_constructions.get.doorConstruction
          break if !door_construction.empty?
        end
      end
    end
    
    if door_construction.nil? || door_construction.empty?
      runner.registerWarning("Door construction not found in construction set, door will not be added")
      return true
    end
    
    door_construction = door_construction.get
    door_height = 2.1336  # 7 feet in meters
    
    # Get the surface vertices
    vertices = door_surface.vertices
    if vertices.size != 4
      runner.registerWarning("Door surface has #{vertices.size} vertices (expected 4), skipping door")
      return true
    end
    
    # Find the bottom two vertices (minimum z-coordinates) and top two vertices
    z_coords = vertices.map { |v| v.z }
    min_z = z_coords.min
    max_z = z_coords.max
    
    bottom_vertices = vertices.select { |v| (v.z - min_z).abs < 0.01 }
    top_vertices = vertices.select { |v| (v.z - max_z).abs < 0.01 }
    
    if bottom_vertices.size != 2 || top_vertices.size != 2
      runner.registerWarning("Door surface doesn't have 2 bottom and 2 top vertices, skipping door")
      return true
    end
    
    # Order bottom vertices left to right
    if bottom_vertices[0].x > bottom_vertices[1].x
      bottom_vertices.reverse!
    elsif (bottom_vertices[0].x - bottom_vertices[1].x).abs < 0.01
      if bottom_vertices[0].y > bottom_vertices[1].y
        bottom_vertices.reverse!
      end
    end
    
    v_bottom_left = bottom_vertices[0]
    v_bottom_right = bottom_vertices[1]
    
    # Order top vertices left to right
    if top_vertices[0].x > top_vertices[1].x
      top_vertices.reverse!
    elsif (top_vertices[0].x - top_vertices[1].x).abs < 0.01
      if top_vertices[0].y > top_vertices[1].y
        top_vertices.reverse!
      end
    end
    
    v_top_left = top_vertices[0]
    v_top_right = top_vertices[1]
    
    # Calculate wall dimensions
    wall_vector = v_bottom_right - v_bottom_left
    wall_width = wall_vector.length
    wall_height = (v_top_left - v_bottom_left).length
    
    # Check if wall is wide enough for the door
    if wall_width < door_width + 0.1
      runner.registerWarning("Door surface too narrow for door (#{wall_width.round(2)}m < #{(door_width + 0.1).round(2)}m)")
      return true
    end
    
    # Center the door on the wall horizontally
    offset_from_left = (wall_width - door_width) / 2.0
    
    # Create unit vectors
    wall_unit = OpenStudio::Vector3d.new(wall_vector.x / wall_width,
                                          wall_vector.y / wall_width,
                                          wall_vector.z / wall_width)
    
    up_vector = v_top_left - v_bottom_left
    up_unit = OpenStudio::Vector3d.new(up_vector.x / wall_height,
                                        up_vector.y / wall_height,
                                        up_vector.z / wall_height)
    
    # Calculate door corner positions
    wall_offset = OpenStudio::Vector3d.new(wall_unit.x * offset_from_left,
                                            wall_unit.y * offset_from_left,
                                            wall_unit.z * offset_from_left)
    wall_width_vec = OpenStudio::Vector3d.new(wall_unit.x * door_width,
                                               wall_unit.y * door_width,
                                               wall_unit.z * door_width)
    door_height_vec = OpenStudio::Vector3d.new(up_unit.x * door_height,
                                                up_unit.y * door_height,
                                                up_unit.z * door_height)
    
    # Create door corners - starting from bottom left of wall
    door_v0 = v_bottom_left + wall_offset
    door_v1 = door_v0 + wall_width_vec
    door_v2 = door_v1 + door_height_vec
    door_v3 = door_v0 + door_height_vec
    
    door_vertices = OpenStudio::Point3dVector.new
    door_vertices << door_v0
    door_vertices << door_v1
    door_vertices << door_v2
    door_vertices << door_v3
    
    # Create the door subsurface
    door = OpenStudio::Model::SubSurface.new(door_vertices, model)
    door.setName("Entry Door")
    door.setSubSurfaceType("Door")
    door.setSurface(door_surface)
    door.setConstruction(door_construction)
    
    # Check if door orientation matches base surface
    # Door and surface should face the same direction (azimuths within ~1 degree)
    door_azimuth = door.azimuth
    surface_azimuth = door_surface.azimuth
    azimuth_diff = (door_azimuth - surface_azimuth).abs
    
    # Handle wrap-around (e.g., 359° vs 1° should be 2° difference, not 358°)
    if azimuth_diff > Math::PI
      azimuth_diff = 2 * Math::PI - azimuth_diff
    end
    
    # If azimuths differ by more than 90 degrees, door is facing wrong way
    if azimuth_diff > Math::PI / 2
      runner.registerInfo("Door azimuth (#{(door_azimuth * 180 / Math::PI).round(1)}°) differs from surface (#{(surface_azimuth * 180 / Math::PI).round(1)}°) - reversing door vertices")
      
      # Reverse door vertices
      reversed_door_vertices = OpenStudio::Point3dVector.new
      (door_vertices.size - 1).downto(0) do |i|
        reversed_door_vertices << door_vertices[i]
      end
      door.setVertices(reversed_door_vertices)
      
      runner.registerInfo("Door orientation corrected to match base surface")
    end
    
    runner.registerInfo("Added door to #{door_surface.name} (#{door_width.round(2)}m x #{door_height.round(2)}m) at floor level")
    
    return true
  end

  # Add infiltration
  def add_infiltration(model, runner, ach50, cfa)
    # Convert ACH50 to natural ACH (simplified conversion)
    n_factor = 17.0  # Height correction factor
    ach_natural = ach50 / n_factor

    # Set the air changes per hour on the infiltration objects defined in space types
    model.getSpaceTypes.each do |space_type|
      space_type.spaceInfiltrationDesignFlowRates.each do |infiltration|
        infiltration.setAirChangesperHour(ach_natural)
        runner.registerInfo("Set infiltration for space type #{space_type.name}: #{ach_natural.round(3)} ACH")
      end
    end
    
    # Verify that spaces will inherit infiltration from their space types
    spaces_with_infiltration = 0
    model.getSpaces.each do |space|
      space_type = space.spaceType
      if !space_type.empty?
        if space_type.get.spaceInfiltrationDesignFlowRates.size > 0
          spaces_with_infiltration += 1
        end
      end
    end
    
    runner.registerInfo("#{spaces_with_infiltration} spaces will inherit infiltration from their space types")

    return true
  end

  # Add HVAC system
  def add_hvac_system(model, runner, system_type, cooling_seer, heating_efficiency)
    # Get all thermal zones
    zones = model.getThermalZones.sort

    if zones.empty?
      runner.registerError("No thermal zones found")
      return false
    end

    # Create air loop
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("Residential HVAC System")

    # Create supply components
    supply_fan = OpenStudio::Model::FanConstantVolume.new(model)
    supply_fan.setFanEfficiency(0.6)
    supply_fan.setPressureRise(500)

    # Add heating coil based on system type
    if system_type.include?('Gas Furnace')
      heating_coil = OpenStudio::Model::CoilHeatingGas.new(model)
      heating_coil.setGasBurnerEfficiency(heating_efficiency)
    elsif system_type.include?('Electric Furnace')
      heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
      heating_coil.setEfficiency(heating_efficiency)
    else  # Heat pump
      heating_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model)
      # Convert HSPF to COP (approximate)
      cop = heating_efficiency * 0.3 + 1.0
      heating_coil.setRatedCOP(cop)
    end

    # Add cooling coil
    if system_type.include?('Heat Pump') || system_type.include?('Air Conditioner')
      cooling_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model)
      # Convert SEER to COP (approximate)
      cop = cooling_seer / 3.5
      cooling_coil.setRatedCOP(cop)
    end

    # Add components to air loop
    supply_fan.addToNode(air_loop.supplyInletNode)
    heating_coil.addToNode(air_loop.supplyInletNode) if heating_coil
    cooling_coil.addToNode(air_loop.supplyInletNode) if cooling_coil

    # Add zones to air loop
    zones.each do |zone|
      terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
      runner.registerInfo("Added HVAC to zone: #{zone.name}")
    end
    
    # Add SetpointManager:SingleZone:Reheat to control supply air temperature
    # This controls the supply air temperature based on the first zone's heating/cooling needs
    control_zone = zones.first
    setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
    setpoint_mgr.setName('Air Loop Setpoint Manager')
    setpoint_mgr.setControlZone(control_zone)
    setpoint_mgr.setMinimumSupplyAirTemperature(13.0)  # 13°C (55°F)
    setpoint_mgr.setMaximumSupplyAirTemperature(40.0)  # 40°C (104°F)
    setpoint_mgr.addToNode(air_loop.supplyOutletNode)
    
    runner.registerInfo("Added SetpointManager:SingleZone:Reheat controlling to zone: #{control_zone.name}")

    runner.registerInfo("Created #{system_type} system")
    return true
  end

  # Add water heater
  def add_water_heater(model, runner, dhw_type, efficiency, schedules)
    # Create water heater
    water_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
    water_heater.setName(dhw_type)
    water_heater.setTankVolume(0.19)  # 50 gallons in m³
    water_heater.setHeaterThermalEfficiency(efficiency)
    
    # Set setpoint temperature schedule
    if schedules && schedules[:wh_setpoint]
      water_heater.setSetpointTemperatureSchedule(schedules[:wh_setpoint])
      runner.registerInfo("Set water heater setpoint schedule")
    end
    
    # Set ambient temperature schedule (temperature of space where water heater is located)
    if schedules && schedules[:ambient_temp]
      water_heater.setAmbientTemperatureSchedule(schedules[:ambient_temp])
      water_heater.setAmbientTemperatureIndicator('Schedule')
      runner.registerInfo("Set water heater ambient temperature schedule")
    end

    if dhw_type.include?('Gas')
      water_heater.setHeaterFuelType('NaturalGas')
      water_heater.setHeaterMaximumCapacity(10000)
    else
      water_heater.setHeaterFuelType('Electricity')
      water_heater.setHeaterMaximumCapacity(4500)
    end

    # Create plant loop
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName('Domestic Hot Water Loop')
    plant_loop.addSupplyBranchForComponent(water_heater)
    
    # Set plant loop temperatures
    plant_loop.setMaximumLoopTemperature(60.0)  # 60°C
    plant_loop.setMinimumLoopTemperature(10.0)  # 10°C
    
    # Add pump to supply side (required for all plant loops)
    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName('DHW Circulation Pump')
    pump.setRatedFlowRate(0.001)  # 1 L/s = 0.001 m³/s (typical residential DHW pump)
    pump.setRatedPumpHead(29891)  # 10 ft of head = 29891 Pa
    pump.setMotorEfficiency(0.85)
    pump.setPumpControlType('Intermittent')
    pump.addToNode(plant_loop.supplyInletNode)
    
    runner.registerInfo("Added circulation pump to DHW loop")
    
    # Add setpoint manager to control loop temperature
    if schedules && schedules[:wh_setpoint]
      dhw_setpoint_mgr = OpenStudio::Model::SetpointManagerScheduled.new(model, schedules[:wh_setpoint])
      dhw_setpoint_mgr.setName('DHW Loop Setpoint Manager')
      dhw_setpoint_mgr.addToNode(plant_loop.supplyOutletNode)
      runner.registerInfo("Added setpoint manager to DHW loop")
    end
    
    # Create WaterUse:Equipment:Definition
    wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    wu_def.setName('Residential Water Use Equipment Definition')
    wu_def.setPeakFlowRate(0.00012)  # 1.9 gpm = 0.00012 m³/s (typical residential fixture)
    wu_def.setEndUseSubcategory('Domestic Hot Water')
    
    # Set target and sensible/latent fractions
    if schedules && schedules[:hw_temp]
      wu_def.setTargetTemperatureSchedule(schedules[:hw_temp])
    end
    wu_def.setSensibleFractionSchedule(model.alwaysOnDiscreteSchedule)
    wu_def.setLatentFractionSchedule(model.alwaysOnDiscreteSchedule)
    
    # Create WaterUse:Equipment
    water_use_equipment = OpenStudio::Model::WaterUseEquipment.new(wu_def)
    water_use_equipment.setName('Residential Hot Water Use')
    
    # Set flow rate schedule
    if schedules && schedules[:hw_flow]
      water_use_equipment.setFlowRateFractionSchedule(schedules[:hw_flow])
      runner.registerInfo("Set hot water flow rate schedule")
    end
    
    # Create WaterUse:Connections
    water_use_connections = OpenStudio::Model::WaterUseConnections.new(model)
    water_use_connections.setName('Residential Water Use Connections')
    water_use_connections.addWaterUseEquipment(water_use_equipment)
    
    # Add water use connections to the demand side of the plant loop
    plant_loop.addDemandBranchForComponent(water_use_connections)

    runner.registerInfo("Created #{dhw_type} with EF=#{efficiency}")
    runner.registerInfo("Created water use equipment with connections on DHW loop")
    return true
  end

  # Add internal loads
  def add_internal_loads(model, runner, cfa)
    # Internal loads (People, Lights, Electric Equipment) are now assigned to space types
    # Spaces will automatically inherit these loads from their assigned space type
    
    runner.registerInfo("Internal loads (lighting, plug loads, and occupancy) are assigned to space types")
    runner.registerInfo("Spaces will inherit loads from their assigned space type:")
    
    model.getSpaceTypes.each do |space_type|
      lights_count = space_type.lights.size
      equipment_count = space_type.electricEquipment.size
      people_count = space_type.people.size
      
      runner.registerInfo("  #{space_type.name}: #{lights_count} lighting, #{equipment_count} equipment, #{people_count} occupancy definitions")
    end
    
    return true
  end

  # Add thermostats
  def add_thermostats(model, runner)
    # Create temperature schedule type limits for thermostats
    temp_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    temp_limits.setName('Temperature')
    temp_limits.setNumericType('Continuous')
    temp_limits.setUnitType('Temperature')
    
    # Create heating setpoint schedule with setback (nighttime and daytime setback)
    heating_setpoint_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    heating_setpoint_sch.setName('Residential Heating Setpoint')
    heating_setpoint_sch.setScheduleTypeLimits(temp_limits)
    
    heating_default = heating_setpoint_sch.defaultDaySchedule
    heating_default.setName('Residential Heating Setpoint Default')
    heating_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 18.0)   # Night setback: 18°C (64°F)
    heating_default.addValue(OpenStudio::Time.new(0, 9, 0, 0), 20.0)   # Morning: 20°C (68°F)
    heating_default.addValue(OpenStudio::Time.new(0, 17, 0, 0), 18.0)  # Day setback: 18°C (64°F)
    heating_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 20.0)  # Evening: 20°C (68°F)
    heating_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 18.0)  # Night setback: 18°C (64°F)
    
    # Weekend heating (occupied all day)
    heating_weekend_rule = OpenStudio::Model::ScheduleRule.new(heating_setpoint_sch)
    heating_weekend_rule.setName('Residential Heating Setpoint Weekend')
    heating_weekend_rule.setApplySaturday(true)
    heating_weekend_rule.setApplySunday(true)
    heating_weekend_day = heating_weekend_rule.daySchedule
    heating_weekend_day.addValue(OpenStudio::Time.new(0, 6, 0, 0), 18.0)   # Night: 18°C
    heating_weekend_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 20.0)  # Day: 20°C
    heating_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 18.0)  # Night: 18°C
    
    # Create cooling setpoint schedule with setup (higher setpoint when away/sleeping)
    cooling_setpoint_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    cooling_setpoint_sch.setName('Residential Cooling Setpoint')
    cooling_setpoint_sch.setScheduleTypeLimits(temp_limits)
    
    cooling_default = cooling_setpoint_sch.defaultDaySchedule
    cooling_default.setName('Residential Cooling Setpoint Default')
    cooling_default.addValue(OpenStudio::Time.new(0, 6, 0, 0), 27.0)   # Night setup: 27°C (81°F)
    cooling_default.addValue(OpenStudio::Time.new(0, 9, 0, 0), 24.0)   # Morning: 24°C (75°F)
    cooling_default.addValue(OpenStudio::Time.new(0, 17, 0, 0), 27.0)  # Day setup: 27°C (81°F)
    cooling_default.addValue(OpenStudio::Time.new(0, 22, 0, 0), 24.0)  # Evening: 24°C (75°F)
    cooling_default.addValue(OpenStudio::Time.new(0, 24, 0, 0), 27.0)  # Night setup: 27°C (81°F)
    
    # Weekend cooling (occupied all day)
    cooling_weekend_rule = OpenStudio::Model::ScheduleRule.new(cooling_setpoint_sch)
    cooling_weekend_rule.setName('Residential Cooling Setpoint Weekend')
    cooling_weekend_rule.setApplySaturday(true)
    cooling_weekend_rule.setApplySunday(true)
    cooling_weekend_day = cooling_weekend_rule.daySchedule
    cooling_weekend_day.addValue(OpenStudio::Time.new(0, 6, 0, 0), 27.0)   # Night: 27°C
    cooling_weekend_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 24.0)  # Day: 24°C
    cooling_weekend_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 27.0)  # Night: 27°C

    model.getThermalZones.each do |zone|
      thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostat.setHeatingSetpointTemperatureSchedule(heating_setpoint_sch)
      thermostat.setCoolingSetpointTemperatureSchedule(cooling_setpoint_sch)
      zone.setThermostatSetpointDualSetpoint(thermostat)

      runner.registerInfo("Added thermostat to zone: #{zone.name}")
    end
    
    runner.registerInfo("Created residential thermostat schedules with setback/setup periods")
    return true
  end

  # Create constant schedule
  def create_constant_schedule(model, name, value)
    schedule = OpenStudio::Model::ScheduleConstant.new(model)
    schedule.setName(name)
    schedule.setValue(value)
    return schedule
  end
end

# register the measure to be used by the application
BuildSimpleResidentialModel.new.registerWithApplication
