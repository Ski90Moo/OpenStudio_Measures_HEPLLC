

###### (Automatically generated documentation)

# Add Heat Pump Ahead Of Boiler

## Description
Connects an existing heating heat pump that is not yet on a plant loop (plant loop EIR, water-to-water equation fit, or fuel-fired air-to-water) in series ahead of a hot water boiler, so the heat pump preheats the return water and the boiler trims to the loop supply temperature. The heat pump's leaving water temperature follows the loop's outdoor air reset but is capped at a maximum the heat pump can deliver. Use it after a measure that creates the heat pump, such as Create Air-to-Water Heat Pump, and after the loop has an outdoor air reset, such as from Hot Water Supply Outdoor Air Reset.

## Modeler Description
Supports HeatPumpPlantLoopEIRHeating, HeatPumpWaterToWaterEquationFitHeating and HeatPumpAirToWaterFuelFiredHeating. HeatPumpAirToWater is not supported: in OpenStudio 3.11 the forward translator crashes when a setpoint manager is on its heating mode's outlet node. Adds the selected heat pump at the boiler's inlet node, so it sits in series on the boiler's branch. The loop is the boiler's plant loop, which must have a SetpointManagerOutdoorAirReset on its supply outlet. The heat pump outlet gets a SetpointManagerOutdoorAirReset that equals min(maximum LWT, loop reset): its low-OA point moves to the outdoor temperature where the loop reset crosses the cap. With a setpoint manager on its outlet the heat pump is dispatched by PlantEquipmentOperation:ComponentSetpoint (for the EIR heat pump ControlType is also set to Setpoint; the other types have no such field). Boiler trim control Load leaves the boiler in the load-based heating scheme. Setpoint gives the boiler outlet its own reset matching the loop and sets the boiler flow mode to LeavingSetpointModulated; EnergyPlus then requests design flow continuously, which raises pump energy. A water-source heat pump whose source side is not connected to a condenser loop is reported as a warning.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Heat pump
Heating heat pump not yet connected to a loop: HeatPump:PlantLoop:EIR:Heating, HeatPump:WaterToWater:EquationFit:Heating, or HeatPump:AirToWater:FuelFired:Heating. 'First unconnected heat pump' takes the first one found when the measure runs, for use after a measure in the same workflow that creates the heat pump.
**Name:** hp_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["First unconnected heat pump"]


### Boiler
Hot water boiler on a plant loop. The heat pump is inserted at its inlet node.
**Name:** boiler_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** []


### Maximum heat pump leaving water temperature (F)
Cap on the heat pump's leaving water setpoint, deg F. Above it the boiler supplies the rest of the loop's reset temperature.
**Name:** max_lwt_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Boiler trim control
Load: the boiler stays in the load-based heating scheme and its flow follows coil demand. Setpoint: the boiler gets its own outdoor air reset (component setpoint scheme); EnergyPlus then requests design flow continuously, which raises pump energy.
**Name:** boiler_control,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Load", "Setpoint"]






