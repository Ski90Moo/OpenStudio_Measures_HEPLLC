

###### (Automatically generated documentation)

# Set IdealAirLoads to Control Humidity

## Description
Configures humidity controls on the HVACTemplate:Zone:IdealLoadsAirSystem for a specified thermal zone. Reads the zone's ZoneControl:Humidistat, computes daily average setpoints from its humidifying and dehumidifying schedules, and applies them along with the user-selected control types to the ideal loads object. Dehumidification supports Humidistat, ConstantSensibleHeatRatio, ConstantSupplyHumidityRatio, and None. Humidification supports Humidistat, ConstantSupplyHumidityRatio, and None. If the user selects Yes for Delete ZoneControl:Humidistat, the humidistat object is deleted from the model after processing; its referenced schedules are left in place..

## Modeler Description
Locates ZoneControl:Humidistat for the specified zone and traces its humidifying and dehumidifying schedule references through the Schedule:Year to Schedule:Week:Daily to Schedule:Day:Interval/Hourly chain to compute a daily weighted average for each setpoint. The averages are written to the Humidification Setpoint and Dehumidification Setpoint fields of HVACTemplate:Zone:IdealLoadsAirSystem. When ConstantSupplyHumidityRatio is selected, the Minimum Cooling Supply Humidity Ratio or Maximum Heating Supply Humidity Ratio field is set from the user-supplied humidity ratio value. When Dehumidification Control Type is ConstantSensibleHeatRatio, the Cooling Sensible Heat Ratio field is set from the user-supplied value. If Delete ZoneControl:Humidistat is set to Yes, the ZoneControl:Humidistat object for the zone is then removed from the workspace (its referenced schedules are left untouched); if set to No, the humidistat object is left in place. NOTE: As of EnergyPlus 25.1, the ZoneControl:Humidistat must be deleted so as not to conflict with the EnergyPlus ExpandObjects.  Also note the ExpandObjects will replace any schedules with constant 60% Dehumidification and 30% Humidification schedules. LIMITATION: The IdealLoadsAirSystem Humidistat dehumidification control is simplified—it is not a full dehumidification-with-reheat system and therefore will not provide accurate accounting of energy use for humidity control.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Thermal Zone Name
Enter the exact thermal zone name (e.g., TZ:01-FCU-29B-BAKERY-DINING)
**Name:** thermal_zone_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Dehumidification Control Type (Ideal Loads)
Select the dehumidification control type for the IdealLoadsAirSystem.
**Name:** ideal_loads_dehumidification_control_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["ConstantSensibleHeatRatio", "Humidistat", "ConstantSupplyHumidityRatio", "None"]


### Humidification Control Type (Ideal Loads)
Select the humidification control type for the IdealLoadsAirSystem.
**Name:** ideal_loads_humidification_control_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Humidistat", "ConstantSupplyHumidityRatio", "None"]


### Dehumidification Constant Supply Humidity Ratio (kgWater/kgDryAir)
Used when Dehumidification Control Type is ConstantSupplyHumidityRatio. Sets Minimum Cooling Supply Humidity Ratio.
**Name:** dehumidification_supply_humidity_ratio,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Cooling Sensible Heat Ratio (dimensionless)
Used when Dehumidification Control Type is ConstantSensibleHeatRatio. Sets Cooling Sensible Heat Ratio.
**Name:** cooling_sensible_heat_ratio,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Humidification Constant Supply Humidity Ratio (kgWater/kgDryAir)
Used when Humidification Control Type is ConstantSupplyHumidityRatio. Sets Maximum Heating Supply Humidity Ratio.
**Name:** humidification_supply_humidity_ratio,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Delete ZoneControl:Humidistat for the Thermal Zone
If Yes, the ZoneControl:Humidistat object found for the thermal zone is deleted from the model after processing.
**Name:** delete_humidistat,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Yes", "No"]






