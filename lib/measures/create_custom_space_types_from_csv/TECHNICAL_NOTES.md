# Technical Implementation Notes

## Overview

This document provides technical details about the OpenStudio measure implementation for creating custom space types from CSV files.

## Architecture

### File Path Flexibility

The measure supports three types of file paths for maximum flexibility:

1. **Absolute Paths**
   - Example (Windows): `C:/Users/Name/Documents/SpaceTypes.csv`
   - Example (Mac/Linux): `/Users/name/documents/SpaceTypes.csv`
   - Used as-is, no transformation needed
   - Useful for network drives or shared locations

2. **Relative Paths**
   - Example: `resources/SpaceTypes.csv`
   - Example: `../shared_data/SpaceTypes.csv`
   - Resolved relative to the measure directory
   - Useful for portable measure packages

3. **Default Paths**
   - Default for SpaceTypes: `resources/SpaceTypes.csv`
   - Default for Schedules: `resources/Schedules.csv`
   - Follows traditional OpenStudio measure structure
   - Backwards compatible with original design

### Data Flow
```
SpaceTypes.csv → Parse Headers → For Each Row → Create Space Type and Objects
                                                    ↓
Schedules.csv  → Parse Schedule Data → Create Schedules (on-demand, no duplicates)
```

### Key Design Decisions

1. **UUID-Based Column Identification**: Uses UUIDs in the header row to identify columns rather than fixed positions
   - Advantage: Flexible column ordering
   - Advantage: Clear documentation of what each column represents
   
2. **On-Demand Schedule Creation**: Schedules are only created when referenced by a space type
   - Advantage: Only creates schedules that are actually used
   - Advantage: Avoids duplicate schedule creation
   
3. **Conditional Object Creation**: Objects are only created if their name field is not blank
   - Advantage: Allows partial specifications (e.g., space type with only lighting)
   - Advantage: Reduces clutter in the model

## Code Structure

### Main Methods

#### `arguments(model)`
Defines the user arguments for the measure:
- **space_types_csv_path**: String argument for SpaceTypes.csv file path
  - Required: true
  - Default: `resources/SpaceTypes.csv`
  - Accepts absolute or relative paths
- **schedules_csv_path**: String argument for Schedules.csv file path
  - Required: true
  - Default: `resources/Schedules.csv`
  - Accepts absolute or relative paths

#### `run(model, runner, user_arguments)`
Main execution method that:
1. Retrieves and validates user arguments
2. Resolves file paths (converts relative paths to absolute)
3. Validates CSV file existence
4. Reads and parses both CSV files
5. Iterates through SpaceTypes.csv rows
6. Creates space types and associated objects
7. Reports results

**File Path Resolution Logic:**
```ruby
if !File.absolute_path?(path)
  path = File.join(measure_dir, path)
end
```
This allows users to specify:
- Absolute paths: `C:/Users/Name/file.csv` (used as-is)
- Relative paths: `resources/file.csv` (resolved relative to measure directory)

#### `create_schedule_from_csv(model, runner, schedule_name, schedules_data, created_schedules)`
Creates OpenStudio ScheduleRuleset objects from Schedules.csv data:
- Checks if schedule already created (uses hash lookup)
- Supports Constant and Hourly schedule types
- Handles multiple day types per schedule
- Creates ScheduleRule objects for different day patterns

#### `get_value_by_uuid(row, headers, uuid)`
Helper method to extract values from CSV rows using UUID identifiers:
- Looks up column index by UUID
- Returns nil for blank or missing values
- Strips whitespace from values

## UUID Reference

### Core Space Type UUIDs
- `d83d8e85-c973-43f1-8010-e8f36dc62725` - CATEGORY (gate for processing row)
- `c318426a-e0cf-4c00-830e-9470f81507bb` - Space Type Name
- `bb3bf4f1-c80b-43b9-93a6-263313c59141` - RGB Red (0-255)
- `f48c2a4a-3151-4163-b625-b93c6c227f62` - RGB Green (0-255)
- `35292a8f-2c31-428e-b12b-ecb42e41f30c` - RGB Blue (0-255)
- `36715673-fabf-4b26-bcb3-54efccbcf6ca` - Default Schedule Set Name

### People UUIDs
- `0e52365f-0968-4865-98c8-5a391db72fe1` - People Definition Name
- `1f550d2e-d956-4855-8f6c-850193633ba2` - People per Space Floor Area (people/m²)
- `7e5f790a-2539-4f59-b04d-75858ff1caa0` - Sensible Heat Fraction (0-1)
- `7c329b17-a9b9-429d-87d6-8d696bb1a0f1` - Occupancy Activity Schedule Name

### Outdoor Air UUIDs
- `f8a27cd2-f746-4301-a112-59d13e40d78d` - OA Specification Name
- `a791e0a0-108f-4ea5-ac55-ffbc9ef41f04` - OA per Person (m³/s/person)
- `03d16ff5-015b-4c1f-89e1-fb9e8f3c323e` - OA per Area (m³/s/m²)
- `41dd9f25-8df0-46e6-9f29-cceef9210ae8` - OA Air Changes per Hour (ACH)

### Electric Equipment UUIDs
- `88a913cc-2e7a-402c-8f68-e04d9aea2bfe` - Equipment Definition Name
- `dd740279-a043-472e-9440-1247838bdebd` - Watts per Floor Area (W/m²)
- `93c3190c-58c6-4fa6-b31d-e972f017b622` - Fraction Latent (0-1)
- `e7668a0e-eeeb-49fe-b68d-e4673ff0492f` - Fraction Radiant (0-1)
- `17a128c0-8bb3-42fe-8fa8-e9b6c9857c61` - Fraction Lost (0-1)
- `922e17af-4f99-4a08-92d5-c8797f685f91` - Schedule Name

### Lights UUIDs
- `8cd22776-3059-4312-be9f-414a4cc9a5d4` - Lights Definition Name
- `da106b8e-74c8-48ae-9585-c42116b2ba37` - Watts per Floor Area (W/m²)
- `37274c8e-ef2a-4273-be16-1568ef1010d8` - Fraction Radiant (0-1)
- `2f6014cb-8ffd-48ef-8c06-e2f22e8f09fb` - Fraction Visible (0-1)
- `06a4bb43-86fe-4d0d-b323-df7f797ddedf` - Schedule Name

### Gas Equipment UUIDs
- `4478951e-a465-46c5-913d-bcea7a66cb2a` - Equipment Definition Name
- `75657b05-6269-49ed-9dde-0685e47cd2e8` - Power per Floor Area (W/m²)
- `d7a052b3-0fd2-4248-aceb-14699019a4a4` - Fraction Latent (0-1)
- `fa38e540-d001-49d9-b3f1-d1a707fc1579` - Fraction Radiant (0-1)
- `297cff0e-3751-4d1e-8c51-b492f8bae160` - Fraction Lost (0-1)
- `be6b6705-67ab-46ec-a6e5-80adf6c48c0a` - Schedule Name

### Infiltration UUIDs
- `f0b3db32-813a-495e-9ca0-dde8056737c8` - Infiltration Object Name
- `821df950-1005-42a1-bb71-94e21d06f843` - Flow per Exterior Surface Area (m³/s/m²)
- `be6b6705-67ab-46ec-a6e5-80adf6c48c0a` - Schedule Name (same as gas equipment)

## Schedule Implementation Details

### Supported Day Types
- `Default` - Applies to all days unless overridden
- `Wkdy` - Monday through Friday
- `Wknd` - Saturday and Sunday
- `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun` - Individual days
- `WntrDsn`, `SmrDsn` - Design days (currently skipped)
- `Hol` - Holidays (currently skipped)

### Schedule Types
1. **Constant**: Single value applies for all 24 hours
2. **Hourly**: 24 individual values (Hr 1 through Hr 24)

### Schedule Type Limits
The measure automatically sets schedule type limits based on the Units column:
- `C` (Celsius) → Temperature schedule
- `W` (Watts) → Power/Activity schedule
- Other units → No specific type limits

### Date Handling
Dates in Schedules.csv use format: `DD-Mon` (e.g., `1-Jan`, `31-Dec`)
- Converted to OpenStudio::Date objects
- Used to set start/end dates for ScheduleRule objects

## OpenStudio Objects Created

### Object Hierarchy
```
SpaceType
├── RenderingColor (RGB values)
├── DefaultScheduleSet
│   ├── PeopleActivityLevelSchedule
│   ├── ElectricEquipmentSchedule
│   ├── LightingSchedule
│   ├── GasEquipmentSchedule
│   └── InfiltrationSchedule
├── DesignSpecificationOutdoorAir
├── People → PeopleDefinition
├── ElectricEquipment → ElectricEquipmentDefinition
├── Lights → LightsDefinition
├── GasEquipment → GasEquipmentDefinition
└── SpaceInfiltrationDesignFlowRate
```

### Definition vs Instance Pattern
The measure follows OpenStudio's pattern of creating:
1. **Definition** objects (e.g., PeopleDefinition) - contain the characteristics
2. **Instance** objects (e.g., People) - reference the definition and associate with space type

This allows:
- Definitions to be shared across multiple instances
- Space types to be assigned to multiple spaces
- Efficient model structure

## Error Handling

### File Existence Checks
```ruby
if !File.exist?(space_types_csv_path)
  runner.registerError("SpaceTypes.csv file not found")
  return false
end
```

### Blank Value Handling
```ruby
def get_value_by_uuid(row, headers, uuid)
  # Returns nil for blank values
  return nil if value.nil? || value.strip.empty?
end
```

### Schedule Not Found Warning
```ruby
if schedule_rows.empty?
  runner.registerWarning("Schedule '#{schedule_name}' not found")
  return nil
end
```

## Performance Considerations

### Schedule Caching
Schedules are stored in a hash after creation:
```ruby
created_schedules[schedule_name] = schedule
```
This prevents:
- Duplicate schedule creation
- Unnecessary CSV parsing
- Wasted model size

### Row Skipping
Rows are efficiently skipped early if CATEGORY is blank:
```ruby
category = get_value_by_uuid(row, headers, category_uuid)
next if category.nil?
```

### Conditional Object Creation
Objects are only created if needed:
```ruby
people_name = get_value_by_uuid(row, headers, people_name_uuid)
if !people_name.nil?
  # Create people object
end
```

## Extension Points

### Adding New Object Types
To add support for new OpenStudio object types:

1. Define UUIDs for the new object's properties
2. Add conditional creation logic in the main loop
3. Create the OpenStudio object and set properties
4. Associate with the space type
5. Handle any associated schedules

Example structure:
```ruby
new_object_name_uuid = 'uuid-here'
new_object_name = get_value_by_uuid(row, headers, new_object_name_uuid)
if !new_object_name.nil?
  new_object = OpenStudio::Model::NewObjectType.new(model)
  new_object.setName(new_object_name)
  # Set other properties
  new_object.setSpaceType(space_type)
end
```

### Custom Schedule Types
To support additional schedule types:

1. Extend `create_schedule_from_csv` method
2. Add new Type handling (e.g., 'Weekly', 'Monthly')
3. Create appropriate OpenStudio schedule objects

### CSV Format Extensions
To support additional CSV formats:

1. Add new UUID constants
2. Extend `get_value_by_uuid` or create new parsing methods
3. Add logic in main processing loop

## Testing Recommendations

### Unit Tests Should Verify
1. CSV parsing with various formats
2. Schedule creation with all day types
3. Conditional object creation (blank name handling)
4. Schedule deduplication
5. Error handling for missing files/schedules

### Integration Tests Should Verify
1. Complete space type creation from sample CSV
2. Schedule association with correct objects
3. DefaultScheduleSet population
4. Model validity after measure execution

## Dependencies

### Ruby Gems
- `csv` (Standard Library) - CSV parsing

### OpenStudio SDK
- OpenStudio::Model::* - All model object types
- OpenStudio::Measure::* - Measure framework
- OpenStudio::Date, OpenStudio::Time - Date/time handling
- OpenStudio::MonthOfYear - Month enumeration

## Known Limitations

1. **Design Day Schedules**: Currently skipped (WntrDsn, SmrDsn)
2. **Holiday Schedules**: Currently skipped (Hol day type)
3. **Activity Level Values**: Read from schedule CSV (Hr 1 value)
4. **Schedule Type Limits**: Only Temperature (C) and Power (W) units supported
5. **Date Ranges**: All schedules use same year (not year-specific)

## Future Enhancements

### Potential Improvements
1. Support for design day schedules
2. Holiday schedule handling
3. More schedule type limits (Fractional, Dimensionless, etc.)
4. Year-specific date handling
5. Schedule CSV validation before processing
6. Batch error reporting (collect all errors before failing)
7. Progress reporting for large CSV files
8. Optional model cleanup (remove unused schedules)

### Advanced Features
1. Support for multiple CSV file sets
2. Space type templating/inheritance
3. Automatic unit conversion
4. Schedule profile visualization
5. CSV export from existing model
6. Diff reporting (changes between runs)

## Version History

### Version 1.0 (Current)
- Initial implementation
- Supports all major space type load objects
- CSV-based configuration
- Schedule creation from DOE Prototype format
- UUID-based column identification

## License

[Insert license information]

## Contributing

To contribute improvements:
1. Test changes with various CSV formats
2. Maintain backward compatibility
3. Document new UUIDs
4. Update README and this technical document
5. Add appropriate error handling
6. Include usage examples
