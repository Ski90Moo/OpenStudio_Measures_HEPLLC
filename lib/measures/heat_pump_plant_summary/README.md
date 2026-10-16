

###### (Automatically generated documentation)

# Heat Pump Plant Summary

## Description
Reports how the heating heat pumps and hot water boilers on the model's plant loops performed: annual and monthly heat delivered, electricity and fuel used, seasonal COP and boiler efficiency, each heat pump's share of the plant's heat, and source temperature statistics including the hours at or below a lockout temperature. Covers plant loop EIR, water-to-water equation fit, fuel-fired air-to-water and air-to-water heat pumps. The hourly outputs it needs are requested automatically.

## Modeler Description
Requests hourly output variables for each heating heat pump and boiler on a plant loop in the last OpenStudio model (or, without a model, for every supported type), reads them from the SQL file for the run period and writes report.html plus runner values. Heat pumps: HeatPumpPlantLoopEIRHeating and HeatPumpWaterToWaterEquationFitHeating ('Heat Pump Load Side Heat Transfer Rate', 'Heat Pump Electricity Rate', 'Heat Pump Source Side Inlet Temperature'); HeatPumpAirToWater with a heating mode on a loop (the same names ending ' in Heating Mode'); HeatPumpAirToWaterFuelFiredHeating ('Fuel-fired Absorption HeatPump Load Side Heat Transfer Rate', '... Fuel Rate', '... Electricity Rate', with outdoor air temperature as the source temperature). Boilers: 'Boiler Heating Rate' and 'Boiler <fuel> Rate'. Hourly average rates in W are summed to Wh. COP = heat / electricity; for the fuel-fired heat pump the fuel-based ratio (heat / fuel) is also given. Source temperature statistics cover all hours of the run period. Cooling heat pumps are not reported.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Lockout temperature (F)
Hours with a heat pump's source temperature (entering source water, or outdoor air for air-source units) at or below this value are counted, deg F.
**Name:** lockout_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






