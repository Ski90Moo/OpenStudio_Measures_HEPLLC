# Quick Reference: File Path Arguments

## Measure Arguments

The measure accepts two required arguments:

### 1. Path to SpaceTypes.csv
**Default:** `resources/SpaceTypes.csv`

### 2. Path to Schedules.csv
**Default:** `resources/Schedules.csv`

---

## Path Types & Examples

### ✅ Absolute Paths (Recommended for Non-Standard Locations)

**Windows:**
```
C:/Users/YourName/Documents/MyProject/SpaceTypes.csv
D:/BuildingData/Schedules.csv
//NetworkDrive/SharedFolder/SpaceTypes.csv
```

**Mac:**
```
/Users/yourname/Documents/MyProject/SpaceTypes.csv
/Volumes/SharedDrive/BuildingData/Schedules.csv
```

**Linux:**
```
/home/yourname/documents/myproject/SpaceTypes.csv
/mnt/shared/building_data/Schedules.csv
```

### ✅ Relative Paths (Relative to Measure Directory)

```
resources/SpaceTypes.csv              ← Default (in resources subdirectory)
data/SpaceTypes.csv                   ← In data subdirectory
SpaceTypes.csv                        ← Same directory as measure.rb
../SpaceTypes.csv                     ← Parent directory
../shared_data/SpaceTypes.csv         ← Parent's subdirectory
../../project_files/SpaceTypes.csv    ← Two levels up
```

---

## Common Scenarios

### Scenario 1: Traditional Setup (Use Defaults)
**Structure:**
```
create_custom_space_types_from_csv/
├── measure.rb
├── measure.xml
└── resources/
    ├── SpaceTypes.csv
    └── Schedules.csv
```
**Arguments:**
- Path to SpaceTypes.csv: `resources/SpaceTypes.csv` ✅ (default)
- Path to Schedules.csv: `resources/Schedules.csv` ✅ (default)

---

### Scenario 2: CSV Files in Same Directory as Measure
**Structure:**
```
create_custom_space_types_from_csv/
├── measure.rb
├── measure.xml
├── SpaceTypes.csv
└── Schedules.csv
```
**Arguments:**
- Path to SpaceTypes.csv: `SpaceTypes.csv`
- Path to Schedules.csv: `Schedules.csv`

---

### Scenario 3: Shared CSV Files for Multiple Projects
**Structure:**
```
OpenStudio/
├── Measures/
│   └── create_custom_space_types_from_csv/
│       ├── measure.rb
│       └── measure.xml
└── SharedData/
    ├── SpaceTypes.csv
    └── Schedules.csv
```
**Arguments:**
- Path to SpaceTypes.csv: `../../SharedData/SpaceTypes.csv`
- Path to Schedules.csv: `../../SharedData/Schedules.csv`

---

### Scenario 4: CSV Files in User Documents
**Windows Structure:**
```
C:/
├── OpenStudio/
│   └── Measures/
│       └── create_custom_space_types_from_csv/
└── Users/
    └── JohnDoe/
        └── Documents/
            └── BuildingData/
                ├── SpaceTypes.csv
                └── Schedules.csv
```
**Arguments:**
- Path to SpaceTypes.csv: `C:/Users/JohnDoe/Documents/BuildingData/SpaceTypes.csv`
- Path to Schedules.csv: `C:/Users/JohnDoe/Documents/BuildingData/Schedules.csv`

---

### Scenario 5: Network Drive
**Windows:**
```
Arguments:
- Path to SpaceTypes.csv: `//CompanyServer/BuildingStandards/SpaceTypes.csv`
- Path to Schedules.csv: `//CompanyServer/BuildingStandards/Schedules.csv`
```

**Mac (Mounted Network Drive):**
```
Arguments:
- Path to SpaceTypes.csv: `/Volumes/BuildingStandards/SpaceTypes.csv`
- Path to Schedules.csv: `/Volumes/BuildingStandards/Schedules.csv`
```

---

## Path Rules

### ✅ DO:
- Use forward slashes `/` (works on all platforms)
- Use absolute paths for files outside measure directory
- Use relative paths for portable measure packages
- Verify files exist at specified paths before running

### ❌ DON'T:
- Use backslashes `\` on Windows (use `/` instead, or escape as `\\`)
- Mix relative and absolute path styles
- Assume relative paths are from your project directory (they're from the measure directory)
- Forget to update paths if you move CSV files

---

## Troubleshooting

### "File not found" Error

**Check 1: Is the path correct?**
- Copy the full path from your file browser
- Verify file name spelling (case-sensitive on Mac/Linux)

**Check 2: Relative path confusion?**
- Relative paths are relative to `create_custom_space_types_from_csv/` directory
- NOT relative to your OpenStudio project file
- NOT relative to your current working directory

**Check 3: File permissions?**
- Ensure the CSV files are readable
- Check network drive is accessible

**Check 4: Path format?**
- Windows: Use `C:/` not `C:\`
- Quotes not needed around paths in OpenStudio UI

---

## Quick Test

To verify your paths are correct:

1. Open OpenStudio Application
2. Load your model
3. Add the measure to "Apply Measure Now"
4. Enter your file paths
5. Click "Run Measure"
6. Check the log for:
   ```
   Reading SpaceTypes.csv from: [your path]
   Reading Schedules.csv from: [your path]
   ```

If you see these messages, your paths are correct!

If you see an error immediately, check your paths.

---

## Platform-Specific Tips

### Windows
- Forward slashes work: `C:/Users/Name/file.csv` ✅
- Backslashes need escaping in some contexts ❌
- Network UNC paths work: `//server/share/file.csv` ✅

### Mac
- Standard Unix paths: `/Users/name/file.csv` ✅
- Case-sensitive file system (usually)
- Mounted volumes: `/Volumes/DriveName/file.csv` ✅

### Linux
- Standard Unix paths: `/home/name/file.csv` ✅
- Case-sensitive file system (always)
- Network mounts vary by setup

---

## Best Practices

1. **For Beginners:** Use default paths with files in `resources/` directory
2. **For Teams:** Use network drive with absolute paths
3. **For Version Control:** Use relative paths within repository
4. **For Multiple Projects:** Use shared data folder with relative paths
5. **For Testing:** Keep test data in measure's resources directory

---

## Examples by Use Case

### Educational Institution (Multiple Students)
```
Path: //UniversityServer/CourseFiles/ARCH5200/SpaceTypes.csv
Benefits: Everyone uses same data, easy to update centrally
```

### Consulting Firm (Project Templates)
```
Path: C:/Company/Standards/2024/SpaceTypes.csv
Benefits: Standardized across all projects, version controlled
```

### Individual Designer (Personal Library)
```
Path: resources/SpaceTypes.csv (default)
Benefits: Portable, self-contained, easy to share
```

### Research Project (Version Control)
```
Path: ../data/SpaceTypes.csv (relative)
Benefits: Works for all team members regardless of install location
```

---

## Still Having Issues?

1. Check the full error message in the OpenStudio log
2. Try an absolute path first to verify file access
3. Verify CSV files are UTF-8 encoded
4. Ensure no special characters in file names
5. Test with the default paths and files in resources/ directory

---

**Remember:** When in doubt, use absolute paths! They're the most explicit and easiest to debug.
