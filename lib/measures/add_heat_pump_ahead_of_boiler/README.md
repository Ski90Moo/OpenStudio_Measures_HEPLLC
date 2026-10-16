

###### (Automatically generated documentation)

# Add Heat Pump Ahead Of Boiler

## Description
Connects an existing heating heat pump that is not yet on a plant loop (plant loop EIR, water-to-water equation fit, or fuel-fired air-to-water) in series ahead of a hot water boiler, so the heat pump preheats the return water and the boiler trims to the loop supply temperature. The heat pump's leaving water temperature follows the loop's existing control, an outdoor air reset or a constant or variable schedule, limited to the lower of the heat pump's maximum and the loop's maximum temperature. A heat pump maximum that varies with outdoor or source temperature (as set by the create measures) is applied each timestep. By default the loop keeps at least the heat pump's design flow, with a bypass for flow the coils do not take. The heat pump's maximum is read from the heat pump when the model has one (as set by Create Air-to-Water Heat Pump or Create Water-to-Water Heat Pump), or entered. Use it after a measure that creates the heat pump, such as Create Air-to-Water Heat Pump or Create Water-to-Water Heat Pump (for a water-source heat pump, also connect its source side, for example with Add Horizontal Trench Ground Loop). The loop's supply outlet must have an outdoor air reset or scheduled temperature setpoint manager.

## Modeler Description
Supports HeatPumpPlantLoopEIRHeating, HeatPumpWaterToWaterEquationFitHeating and HeatPumpAirToWaterFuelFiredHeating. HeatPumpAirToWater is not supported: in OpenStudio 3.11 the forward translator crashes when a setpoint manager is on its heating mode's outlet node. Adds the selected heat pump at the boiler's inlet node, so it sits in series on the boiler's branch. The loop is the boiler's plant loop; its supply outlet must have a SetpointManagerOutdoorAirReset or a SetpointManagerScheduled with control variable Temperature. The cap is the lowest of the maximum LWT argument (0 = not used), the heat pump's maximum and the loop's MaximumLoopTemperature. The heat pump's maximum is read only for HeatPumpPlantLoopEIRHeating: its MaximumSupplyWaterTemperatureCurve (any curve, or a one-variable Table:Lookup, interpolated here because OpenStudio cannot evaluate tables), else the x (leaving water) maximum of its capacity curve. When that curve varies and its lowest value is below the fixed limits, the setpoint manager is capped at the curve's highest value and an EMS program (calling point AfterPredictorAfterHVACManagers) sets the heat pump outlet node setpoint each timestep to min(loop supply outlet setpoint, @CurveValue at the sensor Heat Pump Source Side Inlet Temperature, fixed limits). The curve is read at the source inlet temperature: outdoor air for an air source, entering source water for a water source. EnergyPlus 25.2 does not hold the EIR heat pump's outlet to that curve (tested: with a 105F curve and a 113F setpoint the heat pump delivered 113F), so the setpoint cap is what enforces it. An entered maximum above the heat pump's is reduced to it with a warning; with 0 entered and no heat pump maximum (equation fit, fuel-fired) the measure stops with an error. The heat pump outlet gets a setpoint manager of the same kind equal to min(cap, loop setpoint): for an outdoor air reset, an end above the cap moves along the reset line to where it crosses the cap; for a ScheduleConstant, a new ScheduleConstant; for a ScheduleRuleset, a clone (rules and day schedules) with each day schedule value capped. Other schedule types are rejected. With a setpoint manager on its outlet the heat pump is dispatched by PlantEquipmentOperation:ComponentSetpoint (for the EIR heat pump ControlType is also set to Setpoint; the other types have no such field). Boiler trim control Load leaves the boiler in the load-based heating scheme. Setpoint gives the boiler outlet its own setpoint manager matching the loop's (uncapped) and sets the boiler flow mode to LeavingSetpointModulated; EnergyPlus then requests design flow continuously, which raises pump energy. Heat pump water flow Bypass sets the plant loop's MinimumLoopFlowRate to the heat pump's load side design flow, adds a demand branch with only a PipeAdiabatic if the loop has none, raises a hard-sized MaximumLoopFlowRate to that flow, fixes an autosized one at it (with a warning; EnergyPlus caps the loop flow at its maximum), and sets an EIR heat pump's FlowMode to ConstantFlow. The heat pump must be in series with the whole loop flow (as when the boiler is on the supply outlet run); on a parallel branch a warning is given. A water-source heat pump whose source side is not connected to a condenser loop is reported as a warning; an EIR heat pump counts as water source if its CondenserType is WaterSource or its AdditionalProperties has IntendedCondenserType = WaterSource (set by Create Water-to-Water Heat Pump).

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
Cap on the heat pump's leaving water setpoint, deg F. 0 uses the heat pump's own maximum: its Maximum Supply Water Temperature Curve (set by Create Air-to-Water Heat Pump and Create Water-to-Water Heat Pump), or for a plant loop EIR heat pump without one, its capacity curve's leaving water limit. A value above the heat pump's maximum is reduced to it, and the loop's maximum temperature applies if it is lower still. Water-to-water equation fit and fuel-fired heat pumps carry no maximum in the model, so enter one for them. Above the cap the boiler supplies the rest of the loop's setpoint.
**Name:** max_lwt_f,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Boiler trim control
Load: the boiler stays in the load-based heating scheme and its flow follows coil demand. Setpoint: the boiler gets its own setpoint manager matching the loop's (component setpoint scheme); EnergyPlus then requests design flow continuously, which raises pump energy.
**Name:** boiler_control,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Load", "Setpoint"]


### Heat pump water flow
Bypass: the loop keeps at least the heat pump's design flow, with the excess returning through a demand-side bypass pipe (added if the loop has none), so the heat pump always sees its design flow. Loop flow: the heat pump sees whatever the coils draw, which can fall below the manufacturer's minimum.
**Name:** hp_flow,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Bypass", "Loop flow"]






