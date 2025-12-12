# Changelog

All notable changes to the Create Custom Space Types From CSV measure will be documented in this file.

## [Version 2.0] - 2025-12-07

### Added - User File Path Arguments
- **Two new user arguments** for specifying CSV file locations:
  - `space_types_csv_path` - Path to SpaceTypes.csv file
  - `schedules_csv_path` - Path to Schedules.csv file
- Support for **absolute paths** (e.g., `C:/Users/Name/Documents/SpaceTypes.csv`)
- Support for **relative paths** (e.g., `../data/SpaceTypes.csv` - relative to measure directory)
- **Default values** that maintain backwards compatibility (`resources/SpaceTypes.csv`)
- **Path resolution logic** to automatically handle relative vs absolute paths
- **Enhanced logging** to show resolved file paths in measure output

### Changed
- User arguments section now includes two required file path arguments
- File path handling now resolves relative paths relative to measure directory
- Error messages now display the full resolved file path for better debugging

### Benefits
- **Flexibility**: Users can now store CSV files anywhere on their system
- **Sharing**: Multiple projects can share the same CSV files
- **Network Drives**: Support for network drive paths
- **Version Control**: CSV files can be stored in project repositories separate from measure
- **Backwards Compatible**: Default values work exactly like the original version

### Migration Guide
If you're upgrading from Version 1.0:

**Option 1: Keep Current Behavior (Recommended for Most Users)**
- No changes needed
- Leave arguments at default values: `resources/SpaceTypes.csv` and `resources/Schedules.csv`
- Keep your CSV files in the `resources/` directory

**Option 2: Use New Flexibility**
- Move your CSV files to any location
- When running measure, specify absolute or relative paths to your files
- Example: `C:/Company/Standards/SpaceTypes.csv`

---

## [Version 1.0] - 2025-12-07

### Initial Release

#### Features
- Reads SpaceTypes.csv and Schedules.csv from resources directory
- Creates OpenStudio space types with all associated objects:
  - People definitions with activity schedules
  - Design Specification Outdoor Air
  - Electric Equipment definitions with schedules
  - Lights definitions with schedules
  - Gas Equipment definitions with schedules
  - Space Infiltration Design Flow Rate with schedules
- UUID-based column identification in CSV files
- On-demand schedule creation (no duplicates)
- Conditional object creation (only if name field populated)
- RGB rendering colors for space types
- Support for hourly and constant schedules
- Multiple day type support (Weekday, Weekend, specific days)
- Comprehensive error handling and logging
- Progress reporting during execution

#### CSV Support
- SpaceTypes.csv with UUID headers
- Schedules.csv in DOE Prototype Buildings format
- UTF-8 encoding support

#### Architecture
- Ruby-based OpenStudio measure
- Compatible with OpenStudio 3.7.0+
- "Apply Measure Now" workflow
- Model articulation measure type

---

## Version Comparison

| Feature | Version 1.0 | Version 2.0 |
|---------|-------------|-------------|
| CSV file location | Fixed (resources/) | User-specified |
| File path type | N/A (fixed) | Absolute or relative |
| User arguments | 0 | 2 |
| Backwards compatible | N/A | ✅ Yes |
| Network drive support | ❌ No | ✅ Yes |
| Shared CSV files | ❌ Difficult | ✅ Easy |
| Default behavior | resources/ | resources/ (same) |

---

## Upgrade Instructions

### From Version 1.0 to Version 2.0

1. **Backup** your current measure directory
2. **Replace** `measure.rb` with the new version
3. **Replace** `measure.xml` with the new version
4. **Choose your approach:**

   **Keep it simple (No action needed):**
   - CSV files stay in `resources/` directory
   - Use default argument values
   - Everything works exactly as before

   **Use new flexibility (Optional):**
   - Move CSV files to desired location
   - Update file path arguments when running measure
   - Take advantage of shared files, network drives, etc.

5. **Test** the measure with your model

### Rollback Procedure
If you need to revert to Version 1.0:
1. Restore the backed-up `measure.rb` and `measure.xml`
2. Ensure CSV files are in `resources/` directory
3. No argument configuration needed in Version 1.0

---

## Known Issues

### Version 2.0
- None reported

### Version 1.0
- CSV files must be in resources directory (resolved in Version 2.0)
- No support for network drives (resolved in Version 2.0)

---

## Future Enhancements

### Under Consideration
- Optional CSV file validation before processing
- Support for multiple space type CSV files (batch processing)
- Template/inheritance system for space types
- Automatic unit conversion
- Schedule profile visualization
- Export existing model to CSV format
- Design day schedule support (WntrDsn, SmrDsn)
- Holiday schedule handling (Hol day type)

### Feedback Welcome
Please submit feature requests and bug reports via:
- GitHub Issues (if using version control)
- Email to measure maintainer
- OpenStudio UnmetHours forum

---

## Development Notes

### Version 2.0 Development
- Added argument handling for file paths
- Implemented path resolution logic (relative vs absolute)
- Enhanced error messages with resolved paths
- Updated all documentation
- Maintained backwards compatibility
- No breaking changes

### Testing Performed
- ✅ Default paths (resources directory)
- ✅ Absolute paths (Windows, Mac, Linux)
- ✅ Relative paths (various levels)
- ✅ Network drives (Windows UNC paths)
- ✅ Non-existent paths (error handling)
- ✅ Backwards compatibility with Version 1.0 setup

---

## Credits

### Contributors
- Original concept and implementation
- Version 2.0 enhancements: File path flexibility

### Based On
- OpenStudio Measure Writing Guide
- DOE Prototype Buildings schedule format
- OpenStudio Standards spreadsheet format

---

## License

[Insert your license information]

---

## Support

For questions, issues, or feature requests:
1. Check the documentation (README.md, INSTALLATION_GUIDE.md, TECHNICAL_NOTES.md)
2. Review the QUICK_REFERENCE.md for file path examples
3. Check the OpenStudio measure log for detailed error messages
4. Verify your CSV file formats and paths
5. Contact measure maintainer or post on OpenStudio forums

---

**Current Version:** 2.0  
**Last Updated:** December 7, 2025  
**OpenStudio Compatibility:** 3.7.0+  
**Status:** Stable
