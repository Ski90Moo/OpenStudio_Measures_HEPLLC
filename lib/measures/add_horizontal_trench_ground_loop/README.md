

###### (Automatically generated documentation)

# Add Horizontal Trench Ground Loop

## Description
Creates a ground loop for a water-source heat pump: a condenser loop with a constant-speed pump and a horizontal trench ground heat exchanger in soil described by its thermal properties and a Kusuda-Achenbach undisturbed ground temperature model, filled with water or propylene glycol. The selected heat pump's source side is connected to the loop. Supports plant loop EIR and water-to-water equation fit heat pumps, heating or cooling, whose source side is not yet on a loop. Use it after a measure that creates the heat pump, such as Create Water-to-Water Heat Pump.

## Modeler Description
Creates a PlantLoop (condenser sizing) with PumpConstantSpeed (Intermittent, end use subcategory 'Ground Loop Pumps') at the supply inlet, a GroundHeatExchangerHorizontalTrench on a supply branch, and a SetpointManagerScheduled at the supply outlet. The trench is not controlled, so the setpoint is passive; it is also the sizing exit temperature (3 C design temperature difference). The GHX and pump use one design flow: entered, or the heat pump's hard-sized source side flow. The GHX soil properties also feed a new SiteGroundTemperatureUndisturbedKusudaAchenbach, which replaces the GHX's default ground model. Pipe properties are HDPE (0.39 W/m-K, 950 kg/m3, 1900 J/kg-K). The heat pump is added to the loop's demand side with addDemandBranchForComponent. HeatPumpPlantLoopEIRHeating/Cooling show CondenserType AirSource until connected to a source loop. 'First water-source heat pump' takes EIR heat pumps tagged with AdditionalProperties IntendedCondenserType = WaterSource (as Create Water-to-Water Heat Pump does) and equation fit heat pumps. Untagged EIR heat pumps can be picked by name and are converted to water source.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Heat pump
Heat pump whose source side is connected to the new ground loop. 'First water-source heat pump without a source loop' takes the first one found when the measure runs, for use after a measure in the same workflow that creates the heat pump.
**Name:** hp_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["First water-source heat pump without a source loop"]


### Ground loop name
Name of the new condenser loop. Must not match an existing plant loop.
**Name:** loop_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Ground loop design flow (gpm)
Design flow of the ground heat exchanger and pump, gpm. 0 uses the heat pump's source side flow, which must then be hard-sized.
**Name:** design_flow_gpm,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Propylene glycol (%)
Propylene glycol concentration in the ground loop, percent. 0 = plain water.
**Name:** glycol_pct,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Loop setpoint and sizing exit temperature (F)
The ground heat exchanger is not controlled, so this setpoint is passive; it is also the loop's design exit temperature for sizing, deg F.
**Name:** loop_setpoint_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Pump power (hp)
Ground loop pump electric input at design flow, hp. The pump runs at constant speed whenever the heat pump runs.
**Name:** pump_hp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Number of trenches
Number of parallel horizontal trenches, one pipe each.
**Name:** n_trenches,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Trench length (ft)
Pipe length per trench, ft.
**Name:** trench_length_ft,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Spacing between pipes (ft)
Center-to-center horizontal spacing between trench pipes, ft.
**Name:** trench_spacing_ft,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Burial depth (ft)
Depth of the pipes below grade, ft.
**Name:** burial_depth_ft,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Pipe outside diameter (in)
HDPE pipe outside diameter, inches. Default: 1-1/4 in. SDR 11.
**Name:** pipe_od_in,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Pipe inside diameter (in)
HDPE pipe inside diameter, inches. Default: 1-1/4 in. SDR 11.
**Name:** pipe_id_in,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Soil thermal conductivity (Btu/h-ft-F)
Soil thermal conductivity, Btu/h-ft-F. Default: moist silt loam (1.2 W/m-K).
**Name:** soil_k,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Soil density (lb/ft3)
Soil density, lb/ft3. Default: silt loam (1,700 kg/m3).
**Name:** soil_density,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Soil specific heat (Btu/lb-F)
Soil specific heat, Btu/lb-F. Default: moist silt loam (1,400 J/kg-K).
**Name:** soil_cp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Soil moisture content (%)
Volumetric soil moisture content, percent.
**Name:** soil_moisture_pct,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Soil moisture content at saturation (%)
Volumetric soil moisture content at saturation, percent.
**Name:** soil_moisture_sat_pct,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Average ground surface temperature (F)
Annual average ground surface temperature for the Kusuda-Achenbach model, deg F. The mean annual air temperature is a common estimate.
**Name:** ground_avg_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Ground surface temperature amplitude (F)
Amplitude of the annual ground surface temperature swing, deg F (half the difference between the warmest and coldest monthly means).
**Name:** ground_amp_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Day of minimum ground surface temperature
Day of the year on which the ground surface temperature is lowest.
**Name:** ground_phase_days,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






