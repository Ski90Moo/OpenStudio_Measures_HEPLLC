# Replace Chiller with Air Source Heat Pumps

## Description

This OpenStudio measure converts a water-cooled chiller system to air-source heat pumps for both cooling and heating. It performs three main tasks:

1. **Deletes the condenser water loop** - Removes the existing condenser water plant loop with its cooling tower
2. **Replaces the water-cooled chiller** - Substitutes the `Chiller:Electric:EIR` with an air-source `HeatPump:PlantLoop:EIR:Cooling`
3. **Adds heating heat pump** - Installs an air-source `HeatPump:PlantLoop:EIR:Heating` in series with the existing boiler

## Modeler Description

The measure searches through the model's plant loops to identify and modify the relevant HVAC components:

- Identifies the condenser water loop by finding a `CoolingTower:SingleSpeed` component and removes the entire loop
- Locates the `Chiller:Electric:EIR` object on the chilled water loop and replaces it with a `HeatPump:PlantLoop:EIR:Cooling` object
- Finds the `Boiler:HotWater` on the heating water loop and adds a `HeatPump:PlantLoop:EIR:Heating` object in series

The heat pumps are configured with:
- Air-cooled condenser type
- Default COP of 3.5 for cooling and 3.0 for heating
- Autosized capacities (unless specified by user)
- Autosized flow rates

## Measure Type

ModelMeasure

## Taxonomy

- HVAC.Cooling
- HVAC.Heating
- HVAC.Heat Pumps

## Arguments

### Cooling Heat Pump Capacity (W)
**Name:** `cooling_hp_capacity`  
**Type:** Double  
**Required:** No  
**Description:** Reference capacity of the cooling heat pump in Watts. Leave blank to autosize based on cooling loads.

### Heating Heat Pump Capacity (W)
**Name:** `heating_hp_capacity`  
**Type:** Double  
**Required:** No  
**Description:** Reference capacity of the heating heat pump in Watts. Leave blank to autosize based on heating loads.

## Installation

1. Copy the measure folder to your OpenStudio measures directory:
   - Windows: `C:\Users\<username>\OpenStudio\Measures`
   - Mac: `/Users/<username>/OpenStudio/Measures`
   - Linux: `/home/<username>/OpenStudio/Measures`

2. The measure folder should contain:
   - `measure.rb`
   - `measure.xml`
   - `README.md` (this file)

## Usage

### Using "Apply Measure Now" in OpenStudio Application

1. Open your OpenStudio model (`.osm` file)
2. Navigate to the **Measures** tab
3. Click **Apply Measure Now**
4. Select **Replace Chiller with Air Source Heat Pumps** from the list
5. (Optional) Enter specific capacities for the heat pumps, or leave blank to autosize
6. Click **Apply Measure**
7. Review the measure output to confirm all components were successfully modified

### Expected Results

The measure will report:
- Success or failure in deleting the condenser water loop
- Confirmation of chiller replacement with cooling heat pump
- Confirmation of heating heat pump addition in series with boiler

### Warnings and Errors

- **Warning:** "No condenser water loop with CoolingTower:SingleSpeed was found" - The model doesn't have a cooling tower to remove
- **Warning:** "No Boiler:HotWater was found. Heating heat pump was not added" - The model doesn't have a boiler on the hot water loop
- **Error:** "No Chiller:Electric:EIR was found to replace" - The measure cannot find a water-cooled chiller to replace (measure will fail)

## Technical Notes

- The measure is compatible with OpenStudio 3.0.0 and later
- Heat pump objects use default performance curves; you may need to adjust curves for specific equipment
- The heating heat pump is added in series with the boiler, allowing for dual-fuel operation
- All autosized components will be sized during the EnergyPlus simulation
- The measure removes the entire condenser loop, including pumps and any other components

## Assumptions

- The model has a single water-cooled chiller (`Chiller:Electric:EIR`)
- The model has a single condenser water loop with a cooling tower
- The model has a hot water loop with at least one boiler
- Default COP values (3.5 cooling, 3.0 heating) are appropriate for the application

## References

- [OpenStudio SDK Documentation](https://openstudio-sdk-documentation.s3.amazonaws.com/index.html)
- [EnergyPlus Engineering Reference - Air Source Heat Pumps](https://bigladdersoftware.com/epx/docs/24-1/engineering-reference/)

## Version History

- **v1.0.0** (2025-10-29) - Initial release

## Contact

For questions or issues with this measure, please refer to the OpenStudio user community or documentation.
