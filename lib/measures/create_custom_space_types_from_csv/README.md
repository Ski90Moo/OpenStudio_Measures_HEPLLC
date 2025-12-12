

###### (Automatically generated documentation)

# Create Custom Space Types From CSV

## Description
The user can enter custom data into a space type csv file and a schedules csv file.  From these, the measure generates the requested space types.

## Modeler Description
The user can enter custom data into a space type csv file and a schedules csv file.  From these, the measure generates the requested space types.  Key information is identified with the OS: and !- tags; these columns must be completed in order for the measure to run.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Path to SpaceTypes.csv
Full file path to the SpaceTypes.csv file containing space type definitions.
**Name:** space_types_csv_path,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Path to Schedules.csv
Full file path to the Schedules.csv file containing schedule definitions.
**Name:** schedules_csv_path,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false






