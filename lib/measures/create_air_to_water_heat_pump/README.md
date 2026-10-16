

###### (Automatically generated documentation)

# Create Air To Water Heat Pump

## Description
Creates an air-to-water heat pump for heating (HeatPump:PlantLoop:EIR:Heating, air source) from a few catalog values: capacity and COP at one rating point, water flow, and the low-ambient lockout. Performance curves are generated from a Carnot model calibrated to that rating point, so no manufacturer curve data is needed. Defaults represent a ClimaCool UCA modular air-to-water heat pump bank, with operating limits from its catalog. The heat pump is created on its own, not connected to any plant loop: it is not simulated until it is added to the supply side of a hot water loop, by hand in the OpenStudio Application or by another measure. To add by hand, drag the object onto a plant loop from the My Model tab.

## Modeler Description
Adds an unconnected HeatPumpPlantLoopEIRHeating (CondenserType AirSource, ControlType Setpoint) with Timed or no defrost. CapFT is linear in leaving load water temperature (LLT) and outdoor air temperature (OAT): 1 + a(OAT - OAT_rated) + b(LLT - LLT_rated), with a and b entered in percent per deg F. EIRFT is a biquadratic least-squares fit, over a 13 x 13 grid spanning the curve limits, of EIR/EIR_rated = COP_c,rated / COP_c, where COP_c = Tc / (Tc - Te), Tc = LLT + condenser approach and Te = OAT - evaporator approach (K). Both curves take x = LLT and y = OAT in deg C and equal 1.0 at the rating point, so the reference capacity and COP are reproduced there. The second-law efficiency (COP_rated / COP_c,rated) is reported. Either curve can be replaced by entering six biquadratic coefficients. The EIRfPLR curve is the OpenStudio default. No plant loop, setpoint manager or operation scheme is created or changed. The maximum leaving water temperature is stored as the MaximumSupplyWaterTemperatureCurve, a Table:Lookup of outdoor air temperature (deg C): linear between the entered points, constant beyond them. EnergyPlus evaluates that curve at the outdoor dry-bulb but does not hold the outlet to it (tested in 25.2: with a 105F curve and a 113F setpoint the heat pump delivered 113F); Add Heat Pump Ahead Of Boiler reads it and limits the heat pump's setpoint to it, which is what enforces it. MinimumPartLoadRatio is set from the smallest capacity step; below it EnergyPlus cycles the heat pump. Timed defrost multiplies available capacity by 0.909 - 107.33 x (outdoor humidity ratio - coil saturation humidity ratio), about 0.85 to 0.9, below the defrost temperature; if the rated capacity already includes defrost, use None.

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
Heating capacity at the rating point, kBtu/h. Default: 4 x ClimaCool UCA030 at 19F OA / 113F leaving water.
**Name:** capacity_mbh,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rated COP
Heating COP at the rating point, compressor and fans included.
**Name:** cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rating outdoor air temperature (F)
Outdoor dry-bulb at which capacity and COP are rated, deg F.
**Name:** rated_oat_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rating leaving water temperature (F)
Leaving hot water temperature at which capacity and COP are rated, deg F.
**Name:** rated_lwt_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Hot water flow (gpm)
Design water flow through the heat pump, gpm.
**Name:** load_flow_gpm,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Capacity change per F outdoor air (%/F)
Percent change in heating capacity per deg F rise in outdoor air temperature. Positive: more capacity in milder weather.
**Name:** cap_pct_per_f_oat,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Capacity change per F leaving water (%/F)
Percent change in heating capacity per deg F rise in leaving water temperature. Usually negative.
**Name:** cap_pct_per_f_lwt,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Condenser approach (F)
Refrigerant condensing temperature above the leaving water temperature, deg F, used in the Carnot model.
**Name:** cond_approach_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Evaporator approach (F)
Refrigerant evaporating temperature below the outdoor air temperature, deg F, used in the Carnot model.
**Name:** evap_approach_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Low-ambient lockout (F)
The heat pump does not run below this outdoor air temperature, deg F. Default: ClimaCool UCA minimum entering source air in heating, 17F.
**Name:** min_oat_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum leaving water temperature vs outdoor air (F)
Highest water temperature the heat pump can deliver, as comma-separated outdoor air:leaving water pairs in deg F, from the manufacturer's data. Linear between points, constant beyond the end points; one pair gives a constant. Stored as the heat pump's Maximum Supply Water Temperature Curve (a Table:Lookup); Add Heat Pump Ahead Of Boiler uses it to limit the heat pump's setpoint. Default: ClimaCool UCA, 113F at 19F (selection at full load) and 135F at 40F and above (catalog maximum), extended to 110.9F at the 17F minimum.
**Name:** max_supply_points,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum part load ratio
Smallest capacity step as a fraction of full capacity; below it the heat pump cycles. Default: 4 x UCA030 with 2 compressors each, 1/8 = 0.125.
**Name:** min_plr,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Defrost control
Timed: a fixed fraction of each hour is spent defrosting when the outdoor air is below the defrost temperature. None: no defrost penalty.
**Name:** defrost_control,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Timed", "None"]


### Defrost below outdoor air temperature (F)
Defrost is active below this outdoor air temperature, deg F.
**Name:** defrost_max_oat_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Defrost time fraction
Fraction of each hour spent in defrost, 0 to 1 (EnergyPlus default 0.058333, 3.5 minutes per hour).
**Name:** defrost_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve minimum leaving water temperature (F)
Lower limit of the curves' leaving water temperature input, and of the fit range, deg F. Default: ClimaCool UCA minimum leaving hot water, 90F.
**Name:** lwt_min_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve maximum leaving water temperature (F)
Upper limit of the curves' leaving water temperature input, and of the fit range, deg F. Default: ClimaCool UCA maximum leaving hot water, 135F.
**Name:** lwt_max_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve minimum outdoor air temperature (F)
Lower limit of the curves' outdoor air temperature input, and of the fit range, deg F. Default: ClimaCool UCA minimum entering source air in heating, 17F.
**Name:** oat_min_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Curve maximum outdoor air temperature (F)
Upper limit of the curves' outdoor air temperature input, and of the fit range, deg F. Default: ClimaCool UCA maximum entering source air in heating, 100F.
**Name:** oat_max_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### CapFT coefficients (optional)
Leave blank to use the generated curve. Otherwise six comma-separated biquadratic coefficients c1..c6 for f(LLT C, OAT C), normalized to 1.0 at the rating point.
**Name:** capft_override,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### EIRFT coefficients (optional)
Leave blank to use the generated Carnot curve. Otherwise six comma-separated biquadratic coefficients c1..c6 for f(LLT C, OAT C), normalized to 1.0 at the rating point.
**Name:** eirft_override,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false






