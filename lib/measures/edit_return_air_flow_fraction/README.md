

###### (Automatically generated documentation)

# Edit Return Air Flow Fraction

## Description
This modifies the Design Return Air Flow Fraction of Supply Air Flow from the default of 1 for cases where the system return fan never returns as much airflow as the supply fan.

## Modeler Description
This measure is puts a maximum on the return fan airflow. If the fan is set for autosized, it does not affect the sizing of the return fan. It will only limit the return fan flow rate during the simulation.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Air Loop with Return Fan

**Name:** loop_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Return Air Flow Fraction

**Name:** return_fraction,
**Type:** Double,
**Units:** Fraction,
**Required:** true,
**Model Dependent:** false




