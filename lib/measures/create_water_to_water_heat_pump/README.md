

###### (Automatically generated documentation)

# Create Water To Water Heat Pump

## Description
Creates a water-to-water heat pump for heating (HeatPump:PlantLoop:EIR:Heating, water source) from catalog values: capacity and COP at one rating point, load and source water flows, and the minimum entering source temperature. Performance curves are entered as biquadratic coefficients; the defaults are fitted to the WaterFurnace Envision2 NXW600 heating table. The heat pump is created on its own, not connected to any plant loop: it is not simulated until its load side is added to the supply side of a hot water loop and its source side to the demand side of a condenser loop, by hand in the OpenStudio Application or by other measures such as Add Horizontal Trench Ground Loop and Add Heat Pump Ahead Of Boiler. To add by hand, drag the object onto each loop from the My Model tab. Until its source side is on a loop, OpenStudio shows it as air source; connecting the source side makes it water source.

## Modeler Description
Adds an unconnected HeatPumpPlantLoopEIRHeating with ControlType Setpoint. OpenStudio only allows CondenserType WaterSource once the source side is on a plant loop, so the heat pump keeps the default AirSource until then; the intended type is recorded in the object's AdditionalProperties (IntendedCondenserType = WaterSource), which Add Horizontal Trench Ground Loop and Add Heat Pump Ahead Of Boiler read. CapFT and EIRFT are biquadratics in x = leaving load water temperature (LLT, deg C) and y = entering source temperature (EST, deg C), limited to the entered ranges. The rating point is given as entering load temperature; LLT there = ELT + capacity / (500 x load gpm). Each curve is checked against 1.0 at (LLT, EST) and a warning is given if it is off by more than 0.5%. The default coefficients were fitted to the Envision2 NXW600 heating table (100 gpm load / 200 gpm source) and normalized at EST 45F / ELT 100F. The EIRfPLR curve is the OpenStudio default (constant 1.0). No plant loop, setpoint manager or operation scheme is created or changed. The maximum leaving water temperature is stored as the MaximumSupplyWaterTemperatureCurve, a Table:Lookup of entering source temperature (deg C): linear between the entered points, constant beyond them. EnergyPlus 25.2 evaluates that curve at the outdoor dry-bulb rather than the source temperature, and does not hold the outlet to it (tested: with a 105F curve and a 113F setpoint the heat pump delivered 113F); Add Heat Pump Ahead Of Boiler reads it at the heat pump's source inlet temperature and limits the heat pump's setpoint to it, which is what enforces it. MinimumPartLoadRatio is set from the smallest capacity step; below it EnergyPlus cycles the heat pump.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Heat pump name
Name of the new heat pump. Must not match an existing HeatPump:PlantLoop:EIR:Heating.
**Name:** hp_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rated heating capacity (MBH)
Heating capacity at the rating point, kBtu/h. Default: WaterFurnace Envision2 NXW600 at 45F EST / 100F ELT.
**Name:** capacity_mbh,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rated COP
Heating COP at the rating point.
**Name:** cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rating entering source temperature (F)
Entering source (ground loop) water temperature at which capacity and COP are rated, deg F.
**Name:** rated_est_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rating entering load temperature (F)
Entering load (hot water) temperature at which capacity and COP are rated, deg F, as listed in the catalog.
**Name:** rated_elt_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Load side flow (gpm)
Hot water flow through the heat pump, gpm.
**Name:** load_flow_gpm,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Source side flow (gpm)
Source (ground loop) flow through the heat pump, gpm.
**Name:** source_flow_gpm,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum entering source temperature (F)
The heat pump does not run below this entering source temperature, deg F. 25F assumes an antifreeze solution in the source loop; use about 40F for plain water.
**Name:** min_est_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum leaving load water temperature vs entering source (F)
Highest water temperature the heat pump can deliver, as comma-separated entering source:leaving load water pairs in deg F, from the manufacturer's data. Linear between points, constant beyond the end points; one pair gives a constant. Stored as the heat pump's Maximum Supply Water Temperature Curve (a Table:Lookup); Add Heat Pump Ahead Of Boiler uses it to limit the heat pump's setpoint. Default: Envision2 NXW600 heating table at 100 gpm load / 200 gpm source, leaving load water at the highest allowed entering load water (120F at EST 30-70F, 100F at EST 90F).
**Name:** max_supply_points,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum part load ratio
Smallest capacity step as a fraction of full capacity; below it the heat pump cycles. Default: one NXW600 with 2 compressors, 0.5.
**Name:** min_plr,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve minimum leaving load temperature (F)
Lower limit of the curves' leaving load water temperature input, deg F.
**Name:** lwt_min_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve maximum leaving load temperature (F)
Upper limit of the curves' leaving load water temperature input, deg F.
**Name:** lwt_max_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve minimum entering source temperature (F)
Lower limit of the curves' entering source temperature input, deg F.
**Name:** est_min_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve maximum entering source temperature (F)
Upper limit of the curves' entering source temperature input, deg F.
**Name:** est_max_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### CapFT coefficients
Six comma-separated biquadratic coefficients c1..c6 for f(LLT C, EST C), normalized to 1.0 at the rating point. Default: Envision2 NXW600 fit.
**Name:** capft_coeffs,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### EIRFT coefficients
Six comma-separated biquadratic coefficients c1..c6 for f(LLT C, EST C), normalized to 1.0 at the rating point. Default: Envision2 NXW600 fit.
**Name:** eirft_coeffs,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false






