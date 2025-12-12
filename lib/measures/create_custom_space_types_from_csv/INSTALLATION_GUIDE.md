# Installation Guide for Create Custom Space Types From CSV Measure

## Quick Start

This OpenStudio measure creates custom space types from your CSV files. Follow these steps to install and use it.

## Step 1: Create the Measure Directory

Create a new directory for your measure with this structure:

```
create_custom_space_types_from_csv/
├── measure.rb
├── measure.xml
└── resources/
    ├── SpaceTypes.csv
    └── Schedules.csv
```

## Step 2: Copy Files

1. Copy `measure.rb` to the main measure directory
2. Copy `measure.xml` to the main measure directory  
3. Create a `resources` subdirectory
4. Copy your `SpaceTypes.csv` file to the `resources` directory
5. Copy your `Schedules.csv` file to the `resources` directory

## Step 3: Add to OpenStudio and Prepare CSV Files

You now have flexibility in where you store your CSV files. You can:

### Option A: Store in Measure Resources Directory (Traditional)
Copy the entire `create_custom_space_types_from_csv` folder to:
- **Windows**: `C:\Users\[YourUsername]\OpenStudio\Measures\`
- **Mac**: `~/OpenStudio/Measures/`
- **Linux**: `~/OpenStudio/Measures/`

And place CSV files in the `resources` subdirectory (use default argument values).

### Option B: Store CSV Files Anywhere (New Feature)
1. Copy just the measure folder (measure.rb and measure.xml) to your OpenStudio Measures directory
2. Store your CSV files anywhere on your computer
3. When running the measure, specify the full paths to your CSV files

This is useful when:
- Multiple projects share the same CSV files
- CSV files are in a version-controlled repository
- CSV files are on a network drive
- You want to keep data separate from measure code

### Option C: Use from Custom Location
In OpenStudio Application:
1. Go to **Preferences** → **Change My Measures Directory**
2. Select the directory containing your measure
3. Store CSV files in any accessible location
4. Specify paths when running the measure

## Step 4: Run the Measure

1. Open your OpenStudio model
2. Go to the **Measures** tab
3. Find "Create Custom Space Types From CSV"
4. Drag it to **Apply Measure Now**
5. **Configure the file paths:**
   - **Path to SpaceTypes.csv**: Enter the path to your SpaceTypes.csv file
     - Use default `resources/SpaceTypes.csv` if file is in measure's resources directory
     - Use absolute path like `C:/Users/YourName/Documents/SpaceTypes.csv`
     - Use relative path like `../data/SpaceTypes.csv` (relative to measure directory)
   - **Path to Schedules.csv**: Enter the path to your Schedules.csv file
     - Use default `resources/Schedules.csv` if file is in measure's resources directory
     - Use absolute path like `C:/Users/YourName/Documents/Schedules.csv`
     - Use relative path like `../data/Schedules.csv` (relative to measure directory)
6. Click **Run Measure**

### File Path Options

You have three options for specifying file paths:

#### Option A: Default (resources directory)
Leave the default values:
- `resources/SpaceTypes.csv`
- `resources/Schedules.csv`

This assumes your CSV files are in the measure's `resources` subdirectory.

#### Option B: Absolute Paths
Specify the full path to your files:
- Windows: `C:\Users\YourName\Documents\MyProject\SpaceTypes.csv`
- Mac/Linux: `/Users/yourname/Documents/MyProject/SpaceTypes.csv`

#### Option C: Relative Paths
Specify paths relative to the measure directory:
- Same directory as measure: `SpaceTypes.csv`
- Subdirectory: `data/SpaceTypes.csv`
- Parent directory: `../SpaceTypes.csv`
- Another location: `../../shared_data/SpaceTypes.csv`

The measure will:
- ✓ Read both CSV files
- ✓ Create all space types
- ✓ Create associated people, equipment, lighting objects
- ✓ Create schedules from Schedules.csv
- ✓ Report results in the run log

## What Gets Created

For each row in SpaceTypes.csv (where CATEGORY is not empty), the measure creates:

### Always Created:
- **SpaceType** with name and RGB rendering colors
- **DefaultScheduleSet** for the space type

### Created if Name Field is Not Blank:
- **People Definition** with occupancy density and activity schedule
- **Design Specification Outdoor Air** with ventilation rates
- **Electric Equipment Definition** with power density and schedule
- **Lights Definition** with lighting power density and schedule
- **Gas Equipment Definition** with gas power density and schedule
- **Space Infiltration** with infiltration rate and schedule

### Schedules:
- Automatically created from Schedules.csv as needed
- Reused if already created (no duplicates)
- Supports hourly and constant schedules
- Supports multiple day types (Weekday, Weekend, specific days)

## CSV File Requirements

### SpaceTypes.csv
- First row must contain UUID headers
- CATEGORY column (`d83d8e85-c973-43f1-8010-e8f36dc62725`) must not be blank to process row
- File encoding: UTF-8

### Schedules.csv
- Must follow DOE Prototype Buildings format
- Headers: Name, Category, Units, Day Types, Start Date, End Date, Type, Hr 1-24
- File encoding: UTF-8

## Verification

After running the measure, verify in OpenStudio:

1. **Space Types Tab**: Check that new space types appear
2. **Each Space Type**: Should show:
   - Rendering color (if RGB values provided)
   - People loads
   - Equipment loads  
   - Lighting loads
   - Outdoor air specification
   - Infiltration
3. **Schedules Tab**: Check that schedules were created

## Troubleshooting

### Error: "SpaceTypes.csv file not found"
- Check the file path you entered in the argument
- For absolute paths: Ensure the full path is correct (e.g., `C:\Users\...`)
- For relative paths: Remember they're relative to the measure directory, not your current working directory
- On Windows: Use forward slashes `/` or escaped backslashes `\\` in paths
- Verify the file name matches exactly (case-sensitive on Mac/Linux)

### Error: "Schedules.csv file not found"
- Same troubleshooting steps as above for SpaceTypes.csv
- Ensure both CSV files are accessible from the measure location

### File Path Examples

**Windows Absolute:**
```
C:/Users/JohnDoe/Documents/BuildingData/SpaceTypes.csv
```

**Windows Network Drive:**
```
//ServerName/SharedFolder/SpaceTypes.csv
```

**Mac/Linux Absolute:**
```
/Users/johndoe/Documents/BuildingData/SpaceTypes.csv
```

**Relative to Measure Directory:**
```
resources/SpaceTypes.csv
../shared_data/SpaceTypes.csv
../../project_files/SpaceTypes.csv
```

### Error: "Schedule 'XYZ' not found in Schedules.csv"
- Verify the schedule name in SpaceTypes.csv matches a name in Schedules.csv exactly
- Check for extra spaces or different capitalization

### No Space Types Created
- Check that rows in SpaceTypes.csv have a value in the CATEGORY column
- Verify the CATEGORY column UUID is correct in the header row

### Objects Not Created for Some Space Types
- This is expected if the name field for that object type is blank
- Example: If People Name is blank, no people object is created for that space type

## Example Output

After running successfully, you should see output like:

```
Processing space type: BA Automotive Facility_2021WABuilding Code
  Created People: COMNET-REV9WholeBuildingBA Automotive FacilityPeopleDef
  Created Outdoor Air: COMNET-REV9WholeBuildingBA Automotive FacilityVent
  Created Electric Equipment: COMNET-REV9NREL 956/Eley AnalysisDOEPrototypeBA Automotive FacilityElectricalEquipDef
  Created Lights: Washington State Energy Code Commercial TABLE C405.4.2Automotive facilityLightingDef
  Created Gas Equipment: COMNET-REV9California Commercial End-Use Survey (CEUS)93%ThermEffRadiantBA Automotive FacilityGasEquipDef
  Created Infiltration: PNNL-NECB 2011BA Automotive FacilityInfil
Created schedule: BA Automotive FacilityActivity
Created schedule: NECB-E-Electric-Equipment
...
Created 50 space types and 120 schedules.
```

## Support

If you encounter issues:
1. Check the OpenStudio run log for detailed error messages
2. Verify your CSV files are properly formatted
3. Ensure all referenced schedules exist in Schedules.csv
4. Check that file encodings are UTF-8

## Advanced Usage

### Modifying Space Types
Edit SpaceTypes.csv to:
- Add new space types (add new rows)
- Modify load values (change values in existing rows)
- Remove space types (delete rows or blank the CATEGORY column)

### Adding New Schedules
Edit Schedules.csv to:
- Add custom schedules
- Modify existing schedule profiles
- Create schedules for different building types

### Running Multiple Times
The measure can be run multiple times on the same model. It will create new space types each time based on the current CSV content.

## File Structure Summary

```
Your OpenStudio Measures Directory/
└── create_custom_space_types_from_csv/
    ├── measure.rb           ← Main measure code
    ├── measure.xml          ← Measure metadata
    └── resources/           ← Required subdirectory
        ├── SpaceTypes.csv   ← Your space type data
        └── Schedules.csv    ← Your schedule data
```

That's it! Your measure is ready to use.
