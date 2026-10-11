

###### (Automatically generated documentation)

# Disable Chilled Water Cooling

## Description
Turns off a chilled water cooling system for the annual simulation without removing any components. An on/off availability schedule is applied to the chilled water plant loop and to every chilled water cooling coil it serves. The schedule is off all year but can be left on for the summer design day so that equipment sizing still runs. Useful for buildings whose chilled water system is not yet installed or is out of service, while keeping the model ready for when cooling is added.

## Modeler Description
Finds the selected PlantLoop and reuses the ScheduleRuleset with the given name or creates one: default day 0, winter design day 0, summer design day 1 (or 0 if cooling is off for the summer design day too), using an OnOff Discrete/Availability ScheduleTypeLimits. If the loop already has an AvailabilityManagerScheduledOff, it is pointed at the schedule. Otherwise a new one is added at priority 1, ahead of any existing availability managers. A schedule value of 0 forces the loop off. Every CoilCoolingWater whose plantLoop is this loop gets the schedule as its availability schedule. This includes cooling coils inside zone equipment such as fan coils. The parent equipment's own availability schedule is not changed, because it also runs the fan and the heating. Other demand components, such as cooled beams, radiant cooling or fluid-to-fluid heat exchangers, are listed in a warning but not changed. Nothing is removed, and sizing objects are not changed.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Chilled water plant loop
Chilled water PlantLoop to turn off, chosen from the plant loops in the model.
**Name:** chw_loop_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** []


### Off schedule name
Name of the on/off ScheduleRuleset to apply. If a ruleset with this name already exists it is reused as-is; otherwise it is created (off all year, on for the summer design day if selected below).
**Name:** schedule_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Keep cooling available on the summer design day
When true, the new schedule is 1 on the summer design day so design-day sizing simulations still exercise cooling. Ignored when an existing schedule is reused.
**Name:** on_for_summer_design_day,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false






