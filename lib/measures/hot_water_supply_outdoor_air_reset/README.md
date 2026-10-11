

###### (Automatically generated documentation)

# Hot Water Supply Outdoor Air Reset

## Description
Replaces the supply temperature control on a hot water loop, for space heating or service water, with an outdoor air reset. The supply water temperature is held at a high value in cold weather, at a low value in mild weather, and varies linearly in between. All four reset points are entered in degrees F.

## Modeler Description
Finds the selected PlantLoop and removes every setpoint manager on its supply outlet node, then adds a SetpointManagerOutdoorAirReset (control variable Temperature) there. Inputs in deg F are converted to deg C. Only the supply outlet node is changed: setpoint managers on component outlet nodes, such as a boiler's own outlet, are left as they are and listed in the output. Sizing:Plant is not changed. The measure warns if the loop is not sized as a Heating loop, or if the reset runs backward (a higher supply temperature in mild weather).

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Hot water plant loop
Hot water PlantLoop (space heating or service water) to receive the outdoor air reset, chosen from the plant loops in the model.
**Name:** hw_loop_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** []


### Supply temperature at low outdoor temperature (F)
Hot water supply setpoint when the outdoor dry-bulb is at or below the low outdoor temperature, deg F.
**Name:** sp_at_low_oa_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Low outdoor temperature (F)
Outdoor dry-bulb at and below which the low-OA supply setpoint applies, deg F.
**Name:** low_oa_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Supply temperature at high outdoor temperature (F)
Hot water supply setpoint when the outdoor dry-bulb is at or above the high outdoor temperature, deg F.
**Name:** sp_at_high_oa_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### High outdoor temperature (F)
Outdoor dry-bulb at and above which the high-OA supply setpoint applies, deg F. Must be greater than the low outdoor temperature.
**Name:** high_oa_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






