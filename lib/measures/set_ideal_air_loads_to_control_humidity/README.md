

###### (Automatically generated documentation)

# Set IdealAirLoads to Control Humidity

## Description
Finds the ZoneControl:Humidistat for the specified thermal zone, computes daily average setpoints from its humidifying and dehumidifying schedules, applies those setpoints to the HVACTemplate:Zone:IdealLoadsAirSystem object, then deletes the humidistat and its schedules.

## Modeler Description
Finds the ZoneControl:Humidistat for the specified thermal zone, computes daily average setpoints from its humidifying and dehumidifying schedules, applies those setpoints to the HVACTemplate:Zone:IdealLoadsAirSystem object, then deletes the humidistat and its schedules.

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
Enter: ConstantSensibleHeatRatio, Humidistat, ConstantSupplyHumidityRatio, or None
**Name:** ideal_loads_dehumidification_control_type,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Humidification Control Type (Ideal Loads)
Enter: Humidistat, ConstantSupplyHumidityRatio, or None
**Name:** ideal_loads_humidification_control_type,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Dehumidification Constant Supply Humidity Ratio (kgWater/kgDryAir)
Used when Dehumidification Control Type is ConstantSupplyHumidityRatio. Sets Minimum Cooling Supply Humidity Ratio.
**Name:** dehumidification_supply_humidity_ratio,
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






