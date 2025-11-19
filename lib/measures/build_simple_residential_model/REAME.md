# Build Simple Residential Model

## Overview

This OpenStudio measure creates a simple residential building model similar to the ResStock/HPXML approach. It generates complete building geometry, constructions, HVAC systems, and other building components for single-family homes from high-level user inputs.

## Features

- **Flexible Building Geometry**: Create single-family detached, single-family attached, or apartment unit models
- **Multiple Foundation Types**: Support for slab, vented crawlspace, unvented crawlspace, and conditioned basement
- **Comprehensive Envelope Configuration**: Control wall and ceiling R-values, window properties, and window-to-wall ratios
- **Multiple HVAC Systems**: Choose from various heating and cooling systems including heat pumps, furnaces, and mini-splits
- **Water Heating Options**: Gas storage, electric storage, tankless, or heat pump water heaters
- **Weather File Preservation**: Option to preserve weather files and design days when regenerating models
- **Infiltration Control**: Specify air leakage rates

## Arguments

### Model Control

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **Delete Existing Model?** | Boolean | true | If true, removes all existing objects from the model before creating the new residential building. If false, adds to the existing model. |
| **Delete Existing Weather and Design Days?** | Boolean | false | Only applies if "Delete Existing Model" is true. If false, preserves existing WeatherFile and DesignDay objects. If true, removes everything including weather data. |

### Geometry

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **Building Type** | Choice | Single-Family Detached | Options: Single-Family Detached, Single-Family Attached, Apartment Unit |
| **Conditioned Floor Area** | Double | 2000.0 ft² | Total conditioned floor area of the building |
| **Number of Floors Above Grade** | Integer | 2 | Number of above-grade floors |
| **Building Aspect Ratio** | Double | 1.5 | Ratio of front wall length to side wall length |
| **Foundation Type** | Choice | Slab | Options: Slab, Vented Crawlspace, Unvented Crawlspace, Conditioned Basement |

### Building Envelope

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **Wall Assembly R-value** | Double | 13.0 h-ft²-R/Btu | Overall R-value of the wall assembly |
| **Ceiling/Attic Assembly R-value** | Double | 38.0 h-ft²-R/Btu | Overall R-value of the ceiling/attic assembly |
| **Window U-Factor** | Double | 0.33 Btu/h-ft²-R | Window thermal transmittance |
| **Window SHGC** | Double | 0.45 | Window Solar Heat Gain Coefficient |
| **Window to Wall Ratio** | Double | 0.15 | Ratio of window area to wall area |

### HVAC System

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **HVAC System Type** | Choice | Central Air Conditioner with Gas Furnace | Options: Central AC with Gas/Electric Furnace, Air Source Heat Pump, Mini-Split Heat Pump |
| **Cooling System SEER** | Double | 13.0 Btu/W-h | Seasonal Energy Efficiency Ratio for cooling |
| **Heating System Efficiency** | Double | 0.78 | AFUE for furnaces, HSPF for heat pumps |

### Domestic Hot Water

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **Water Heater Type** | Choice | Gas Storage Water Heater | Options: Gas Storage, Electric Storage, Gas Tankless, Heat Pump Water Heater |
| **Water Heater Energy Factor** | Double | 0.59 | Energy Factor (EF) of the water heater |

### Other

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| **Air Leakage (ACH50)** | Double | 7.0 1/h | Air changes per hour at 50 Pascals pressure difference |

## Requirements

- **OpenStudio**: Version 3.0 or higher
- **openstudio-standards gem**: Required for construction and HVAC templates

## Installation

1. Copy the measure folder to your OpenStudio measures directory:
   - Windows: `C:\Users\<username>\OpenStudio\Measures`
   - Mac: `/Users/<username>/OpenStudio/Measures`
   - Linux: `/home/<username>/OpenStudio/Measures`

2. The measure should appear in the OpenStudio Application under the "Whole Building" category.

## Usage

### Basic Workflow

1. **Create a new OpenStudio model** or open an existing one
2. **Add the measure** to your workflow in the OpenStudio Application
3. **Configure arguments** according to your building design
4. **Run the measure** to generate the residential building model

### Common Use Cases

#### Use Case 1: Create a New Residential Model

```ruby
# Default settings (Delete Existing Model = true, Delete Weather = false)
# This will:
# - Remove all existing model objects
# - Preserve weather file and design days
# - Create new 2-story, 2000 ft² residential building
```

**Benefits:**
- Clean slate for new designs
- Weather file remains assigned (no manual reassignment needed)
- Design days preserved for sizing calculations
- Fast iterative design workflow

#### Use Case 2: Complete Fresh Start (Including Weather)

```ruby
# Set both arguments to true
# - Delete Existing Model = true
# - Delete Existing Weather and Design Days = true
```

**Use when:**
- Switching to a completely different climate zone
- Starting a brand new project
- Cleaning up a model with corrupted weather data

#### Use Case 3: Add to Existing Model

```ruby
# Set Delete Existing Model = false
```

**Use when:**
- Adding a residential unit to a multi-building campus
- Preserving existing site features or other buildings
- Building complex mixed-use models

### Weather File Preservation Feature

By default, the measure preserves weather files and design days when deleting the existing model. This is the recommended workflow for residential design:

**Workflow with Weather Preservation (Default):**
1. Assign weather file once (e.g., Chicago TMY3)
2. Run measure → Model deleted, weather preserved ✅
3. Make design changes
4. Run measure again → Weather still assigned ✅
5. Run simulation immediately

**Old Workflow (if you set Delete Weather = true):**
1. Run measure → Everything deleted including weather ❌
2. Open OpenStudio Application
3. Go to Site tab
4. Manually select weather file
5. Wait for download
6. Run simulation

The new default saves time and reduces errors in iterative design workflows.

## Examples

### Example 1: Basic 1500 ft² Ranch Home
```
Building Type: Single-Family Detached
Conditioned Floor Area: 1500 ft²
Number of Floors: 1
Foundation: Slab
HVAC: Central Air Conditioner with Gas Furnace
```

### Example 2: Energy-Efficient 2-Story Home
```
Building Type: Single-Family Detached
Conditioned Floor Area: 2400 ft²
Number of Floors: 2
Wall R-value: 20.0
Ceiling R-value: 49.0
Window U-Factor: 0.25
HVAC: Air Source Heat Pump
Water Heater: Heat Pump Water Heater
Air Leakage: 3.0 ACH50
```

### Example 3: Townhouse Unit
```
Building Type: Single-Family Attached
Conditioned Floor Area: 1800 ft²
Number of Floors: 2
Foundation: Conditioned Basement
HVAC: Mini-Split Heat Pump
```

## Model Components Created

The measure generates the following model components:

1. **Geometry**
   - Building footprint based on floor area and aspect ratio
   - Multiple stories with proper floor heights
   - Foundation/basement spaces
   - Exterior walls, windows, and doors
   - Roof/ceiling assemblies

2. **Constructions**
   - Wall constructions meeting specified R-values
   - Ceiling/attic constructions
   - Foundation constructions (slab, crawlspace, or basement)
   - Window constructions with specified U-factor and SHGC
   - Door constructions

3. **HVAC Systems**
   - Heating and cooling equipment
   - Air distribution systems
   - Thermostats and schedules
   - Properly sized equipment

4. **Domestic Hot Water**
   - Water heater equipment
   - Distribution system
   - Usage schedules

5. **Internal Loads**
   - Lighting (residential occupancy patterns)
   - Plug loads (appliances, electronics)
   - People schedules

6. **Infiltration**
   - Air leakage based on specified ACH50

## Technical Notes

### Object Preservation Logic

When `Delete Existing Weather and Design Days = false` (default):

```ruby
# The measure preserves:
- OS:WeatherFile objects
- OS:SizingPeriod:DesignDay objects

# The measure removes:
- All spaces and thermal zones
- All constructions and materials
- All HVAC equipment and systems
- All internal loads
- All schedules
- Everything else except weather data
```

### Coordinate System

The measure uses the following coordinate conventions:
- Origin (0,0,0) at the southwest corner of the building
- Positive X-axis pointing east
- Positive Y-axis pointing north
- Positive Z-axis pointing up

### Thermal Zoning

- Single thermal zone per floor
- Conditioned spaces only (unconditioned spaces like garages not included)
- Basement/crawlspace may be conditioned or unconditioned depending on foundation type

## Troubleshooting

### Issue: Measure fails to run

**Solution**: Verify that `openstudio-standards` gem is installed:
```bash
gem list openstudio-standards
```

### Issue: Weather file not preserved

**Solution**: Check that:
1. A weather file was assigned before running the measure
2. `Delete Existing Weather and Design Days` is set to `false`
3. `Delete Existing Model` is set to `true`

### Issue: HVAC system not created

**Solution**: Ensure valid HVAC efficiency values are entered (e.g., SEER > 13, AFUE 0.78-0.98)

## Version History

- **v1.1** - Added weather file and design day preservation option
- **v1.0** - Initial release with basic residential modeling capabilities

## License

This measure is licensed under the OpenStudio license. See the header in `measure.rb` for full license text.

## Contributing

Contributions are welcome! Please ensure:
- Code follows OpenStudio measure conventions
- All arguments have appropriate defaults
- The measure runs successfully in OpenStudio Application
- Documentation is updated for new features

## Support

For issues or questions:
1. Check the OpenStudio documentation: https://openstudio.net/
2. Visit the OpenStudio forum: https://unmethours.com/
3. Review ResStock documentation: https://resstock.readthedocs.io/

## Acknowledgments

This measure is inspired by NREL's ResStock project and uses the OpenStudio-Standards gem for construction and HVAC templates.
