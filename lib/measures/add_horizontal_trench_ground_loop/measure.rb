class AddHorizontalTrenchGroundLoop < OpenStudio::Measure::ModelMeasure
  def name
    return "Add Horizontal Trench Ground Loop"
  end

  def description
    return "Creates a ground loop for a water-source heat pump: a condenser loop with a constant-speed pump and a horizontal trench ground heat exchanger in soil described by its thermal properties and a Kusuda-Achenbach undisturbed ground temperature model, filled with water or propylene glycol. The selected heat pump's source side is connected to the loop. Supports plant loop EIR and water-to-water equation fit heat pumps, heating or cooling, whose source side is not yet on a loop. Use it after a measure that creates the heat pump, such as Create Water-to-Water Heat Pump."
  end

  def modeler_description
    return "Creates a PlantLoop (condenser sizing) with PumpConstantSpeed (Intermittent, end use subcategory 'Ground Loop Pumps') at the supply inlet, a GroundHeatExchangerHorizontalTrench on a supply branch, and a SetpointManagerScheduled at the supply outlet. The trench is not controlled, so the setpoint is passive; it is also the sizing exit temperature (3 C design temperature difference). The GHX and pump use one design flow: entered, or the heat pump's hard-sized source side flow. The GHX soil properties also feed a new SiteGroundTemperatureUndisturbedKusudaAchenbach, which replaces the GHX's default ground model. Pipe properties are HDPE (0.39 W/m-K, 950 kg/m3, 1900 J/kg-K). The heat pump is added to the loop's demand side with addDemandBranchForComponent. HeatPumpPlantLoopEIRHeating/Cooling show CondenserType AirSource until connected to a source loop. 'First water-source heat pump' takes EIR heat pumps tagged with AdditionalProperties IntendedCondenserType = WaterSource (as Create Water-to-Water Heat Pump does) and equation fit heat pumps. Untagged EIR heat pumps can be picked by name and are converted to water source."
  end

  FIRST_HP = "First water-source heat pump without a source loop"
  INTENDED_TYPE = 'IntendedCondenserType'

  # Heat pumps whose source side is not on a loop, as [name, IDD type, component, water source intended].
  def candidate_heat_pumps(model)
    hps = []
    { 'HeatPump:PlantLoop:EIR:Heating' => model.getHeatPumpPlantLoopEIRHeatings,
      'HeatPump:PlantLoop:EIR:Cooling' => model.getHeatPumpPlantLoopEIRCoolings }.each do |type, list|
      list.each do |h|
        tag = h.additionalProperties.getFeatureAsString(INTENDED_TYPE)
        hps << [h.name.to_s, type, h, tag.is_initialized && tag.get == 'WaterSource']
      end
    end
    { 'HeatPump:WaterToWater:EquationFit:Heating' => model.getHeatPumpWaterToWaterEquationFitHeatings,
      'HeatPump:WaterToWater:EquationFit:Cooling' => model.getHeatPumpWaterToWaterEquationFitCoolings }.each do |type, list|
      list.each { |h| hps << [h.name.to_s, type, h, true] }
    end
    hps.select { |_, _, c, _| c.secondaryPlantLoop.empty? }
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    hp_names = OpenStudio::StringVector.new
    hp_labels = OpenStudio::StringVector.new
    hp_names << FIRST_HP
    hp_labels << FIRST_HP
    candidate_heat_pumps(model).each do |n, type, _, ws|
      hp_names << n
      hp_labels << (ws ? "#{n} (#{type})" : "#{n} (#{type}, now air source)")
    end
    hp_name = OpenStudio::Measure::OSArgument.makeChoiceArgument("hp_name", hp_names, hp_labels, true)
    hp_name.setDisplayName("Heat pump")
    hp_name.setDescription("Heat pump whose source side is connected to the new ground loop. 'First water-source heat pump without a source loop' takes the first one found when the measure runs, for use after a measure in the same workflow that creates the heat pump.")
    hp_name.setDefaultValue(FIRST_HP)
    args << hp_name
    loop_name = OpenStudio::Measure::OSArgument.makeStringArgument("loop_name", true)
    loop_name.setDisplayName("Ground loop name")
    loop_name.setDescription("Name of the new condenser loop. Must not match an existing plant loop.")
    loop_name.setDefaultValue("Ground Loop")
    args << loop_name
    design_flow_gpm = OpenStudio::Measure::OSArgument.makeDoubleArgument("design_flow_gpm", true)
    design_flow_gpm.setDisplayName("Ground loop design flow (gpm)")
    design_flow_gpm.setDescription("Design flow of the ground heat exchanger and pump, gpm. 0 uses the heat pump's source side flow, which must then be hard-sized.")
    design_flow_gpm.setDefaultValue(0.0)
    args << design_flow_gpm
    glycol_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument("glycol_pct", true)
    glycol_pct.setDisplayName("Propylene glycol (%)")
    glycol_pct.setDescription("Propylene glycol concentration in the ground loop, percent. 0 = plain water.")
    glycol_pct.setDefaultValue(25.0)
    args << glycol_pct
    loop_setpoint_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("loop_setpoint_f", true)
    loop_setpoint_f.setDisplayName("Loop setpoint and sizing exit temperature (F)")
    loop_setpoint_f.setDescription("The ground heat exchanger is not controlled, so this setpoint is passive; it is also the loop's design exit temperature for sizing, deg F.")
    loop_setpoint_f.setDefaultValue(45.0)
    args << loop_setpoint_f
    pump_hp = OpenStudio::Measure::OSArgument.makeDoubleArgument("pump_hp", true)
    pump_hp.setDisplayName("Pump power (hp)")
    pump_hp.setDescription("Ground loop pump electric input at design flow, hp. The pump runs at constant speed whenever the heat pump runs.")
    pump_hp.setDefaultValue(17.5)
    args << pump_hp
    n_trenches = OpenStudio::Measure::OSArgument.makeIntegerArgument("n_trenches", true)
    n_trenches.setDisplayName("Number of trenches")
    n_trenches.setDescription("Number of parallel horizontal trenches, one pipe each.")
    n_trenches.setDefaultValue(32)
    args << n_trenches
    trench_length_ft = OpenStudio::Measure::OSArgument.makeDoubleArgument("trench_length_ft", true)
    trench_length_ft.setDisplayName("Trench length (ft)")
    trench_length_ft.setDescription("Pipe length per trench, ft.")
    trench_length_ft.setDefaultValue(1500.0)
    args << trench_length_ft
    trench_spacing_ft = OpenStudio::Measure::OSArgument.makeDoubleArgument("trench_spacing_ft", true)
    trench_spacing_ft.setDisplayName("Spacing between pipes (ft)")
    trench_spacing_ft.setDescription("Center-to-center horizontal spacing between trench pipes, ft.")
    trench_spacing_ft.setDefaultValue(3.28)
    args << trench_spacing_ft
    burial_depth_ft = OpenStudio::Measure::OSArgument.makeDoubleArgument("burial_depth_ft", true)
    burial_depth_ft.setDisplayName("Burial depth (ft)")
    burial_depth_ft.setDescription("Depth of the pipes below grade, ft.")
    burial_depth_ft.setDefaultValue(4.92)
    args << burial_depth_ft
    pipe_od_in = OpenStudio::Measure::OSArgument.makeDoubleArgument("pipe_od_in", true)
    pipe_od_in.setDisplayName("Pipe outside diameter (in)")
    pipe_od_in.setDescription("HDPE pipe outside diameter, inches. Default: 1-1/4 in. SDR 11.")
    pipe_od_in.setDefaultValue(1.660)
    args << pipe_od_in
    pipe_id_in = OpenStudio::Measure::OSArgument.makeDoubleArgument("pipe_id_in", true)
    pipe_id_in.setDisplayName("Pipe inside diameter (in)")
    pipe_id_in.setDescription("HDPE pipe inside diameter, inches. Default: 1-1/4 in. SDR 11.")
    pipe_id_in.setDefaultValue(1.358)
    args << pipe_id_in
    soil_k = OpenStudio::Measure::OSArgument.makeDoubleArgument("soil_k", true)
    soil_k.setDisplayName("Soil thermal conductivity (Btu/h-ft-F)")
    soil_k.setDescription("Soil thermal conductivity, Btu/h-ft-F. Default: moist silt loam (1.2 W/m-K).")
    soil_k.setDefaultValue(0.693)
    args << soil_k
    soil_density = OpenStudio::Measure::OSArgument.makeDoubleArgument("soil_density", true)
    soil_density.setDisplayName("Soil density (lb/ft3)")
    soil_density.setDescription("Soil density, lb/ft3. Default: silt loam (1,700 kg/m3).")
    soil_density.setDefaultValue(106.1)
    args << soil_density
    soil_cp = OpenStudio::Measure::OSArgument.makeDoubleArgument("soil_cp", true)
    soil_cp.setDisplayName("Soil specific heat (Btu/lb-F)")
    soil_cp.setDescription("Soil specific heat, Btu/lb-F. Default: moist silt loam (1,400 J/kg-K).")
    soil_cp.setDefaultValue(0.3344)
    args << soil_cp
    soil_moisture_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument("soil_moisture_pct", true)
    soil_moisture_pct.setDisplayName("Soil moisture content (%)")
    soil_moisture_pct.setDescription("Volumetric soil moisture content, percent.")
    soil_moisture_pct.setDefaultValue(30.0)
    args << soil_moisture_pct
    soil_moisture_sat_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument("soil_moisture_sat_pct", true)
    soil_moisture_sat_pct.setDisplayName("Soil moisture content at saturation (%)")
    soil_moisture_sat_pct.setDescription("Volumetric soil moisture content at saturation, percent.")
    soil_moisture_sat_pct.setDefaultValue(50.0)
    args << soil_moisture_sat_pct
    ground_avg_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("ground_avg_f", true)
    ground_avg_f.setDisplayName("Average ground surface temperature (F)")
    ground_avg_f.setDescription("Annual average ground surface temperature for the Kusuda-Achenbach model, deg F. The mean annual air temperature is a common estimate.")
    ground_avg_f.setDefaultValue(45.0)
    args << ground_avg_f
    ground_amp_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("ground_amp_f", true)
    ground_amp_f.setDisplayName("Ground surface temperature amplitude (F)")
    ground_amp_f.setDescription("Amplitude of the annual ground surface temperature swing, deg F (half the difference between the warmest and coldest monthly means).")
    ground_amp_f.setDefaultValue(20.3)
    args << ground_amp_f
    ground_phase_days = OpenStudio::Measure::OSArgument.makeDoubleArgument("ground_phase_days", true)
    ground_phase_days.setDisplayName("Day of minimum ground surface temperature")
    ground_phase_days.setDescription("Day of the year on which the ground surface temperature is lowest.")
    ground_phase_days.setDefaultValue(30.0)
    args << ground_phase_days
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    hp_name = runner.getStringArgumentValue("hp_name", user_arguments)
    loop_name = runner.getStringArgumentValue("loop_name", user_arguments)
    design_flow_gpm = runner.getDoubleArgumentValue("design_flow_gpm", user_arguments)
    glycol_pct = runner.getDoubleArgumentValue("glycol_pct", user_arguments)
    loop_setpoint_f = runner.getDoubleArgumentValue("loop_setpoint_f", user_arguments)
    pump_hp = runner.getDoubleArgumentValue("pump_hp", user_arguments)
    n_trenches = runner.getIntegerArgumentValue("n_trenches", user_arguments)
    trench_length_ft = runner.getDoubleArgumentValue("trench_length_ft", user_arguments)
    trench_spacing_ft = runner.getDoubleArgumentValue("trench_spacing_ft", user_arguments)
    burial_depth_ft = runner.getDoubleArgumentValue("burial_depth_ft", user_arguments)
    pipe_od_in = runner.getDoubleArgumentValue("pipe_od_in", user_arguments)
    pipe_id_in = runner.getDoubleArgumentValue("pipe_id_in", user_arguments)
    soil_k = runner.getDoubleArgumentValue("soil_k", user_arguments)
    soil_density = runner.getDoubleArgumentValue("soil_density", user_arguments)
    soil_cp = runner.getDoubleArgumentValue("soil_cp", user_arguments)
    soil_moisture_pct = runner.getDoubleArgumentValue("soil_moisture_pct", user_arguments)
    soil_moisture_sat_pct = runner.getDoubleArgumentValue("soil_moisture_sat_pct", user_arguments)
    ground_avg_f = runner.getDoubleArgumentValue("ground_avg_f", user_arguments)
    ground_amp_f = runner.getDoubleArgumentValue("ground_amp_f", user_arguments)
    ground_phase_days = runner.getDoubleArgumentValue("ground_phase_days", user_arguments)
    # --- begin user logic ---
    f2c = lambda { |f| (f - 32.0) / 1.8 }
    gpm = 6.30902e-5
    candidates = candidate_heat_pumps(model)
    pick = hp_name == FIRST_HP ? candidates.find { |_, _, _, ws| ws } : candidates.find { |n, _, _, _| n == hp_name }
    if pick.nil?
      runner.registerError(hp_name == FIRST_HP ? 'The model has no water-source heat pump whose source side is not already on a loop.' : "Heat pump '#{hp_name}' not found among heat pumps whose source side is not on a loop.")
      return false
    end
    hp_name, hp_type, hp, water_source = pick
    if model.getPlantLoops.any? { |l| l.name.to_s == loop_name }
      runner.registerError("A plant loop named '#{loop_name}' already exists.")
      return false
    end
    if [pump_hp, trench_length_ft, trench_spacing_ft, burial_depth_ft, pipe_od_in, pipe_id_in, soil_k, soil_density, soil_cp].any? { |v| v <= 0 } || n_trenches < 1
      runner.registerError('Pump power, trench count and dimensions, pipe diameters and soil properties must be greater than zero.')
      return false
    end
    if pipe_id_in >= pipe_od_in
      runner.registerError('The pipe inside diameter must be smaller than the outside diameter.')
      return false
    end
    if glycol_pct < 0 || glycol_pct > 100 || soil_moisture_pct < 0 || soil_moisture_pct > soil_moisture_sat_pct || soil_moisture_sat_pct > 100
      runner.registerError('Glycol and soil moisture must be percentages, with moisture content no higher than at saturation.')
      return false
    end
    if design_flow_gpm > 0
      flow = design_flow_gpm * gpm
    else
      src = hp_type.include?('EquationFit') ? hp.referenceSourceSideFlowRate : hp.sourceSideReferenceFlowRate
      if src.empty?
        runner.registerError("'#{hp_name}' has an autosized source side flow; enter a ground loop design flow.")
        return false
      end
      flow = src.get
    end
    runner.registerInitialCondition("'#{hp_name}' (#{hp_type}) has no source loop.")
    runner.registerWarning("'#{hp_name}' was air source; connecting its source side to the ground loop makes it water source.") unless water_source

    gl = OpenStudio::Model::PlantLoop.new(model)
    gl.setName(loop_name)
    if glycol_pct > 0
      gl.setFluidType('PropyleneGlycol')
      gl.setGlycolConcentration(glycol_pct.round)
      gl.setMinimumLoopTemperature(-12.0)
    else
      gl.setFluidType('Water')
      gl.setMinimumLoopTemperature(0.0)
    end
    gl.setMaximumLoopTemperature(40.0)
    sz = gl.sizingPlant
    sz.setLoopType('Condenser')
    sz.setDesignLoopExitTemperature(f2c.call(loop_setpoint_f))
    sz.setLoopDesignTemperatureDifference(3.0)

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName("#{loop_name} Pump")
    pump.setRatedFlowRate(flow)
    pump.setRatedPowerConsumption(pump_hp * 745.7)
    pump.setPumpControlType('Intermittent')
    pump.setEndUseSubcategory('Ground Loop Pumps')
    pump.addToNode(gl.supplyInletNode)

    k_si = soil_k * 1.730735
    rho_si = soil_density * 16.018463
    cp_si = soil_cp * 4186.8
    ghx = OpenStudio::Model::GroundHeatExchangerHorizontalTrench.new(model)
    ghx.setName("#{loop_name} Horizontal Trench GHX")
    ghx.setDesignFlowRate(flow)
    ghx.setTrenchLengthinPipeAxialDirection(trench_length_ft * 0.3048)
    ghx.setNumberofTrenches(n_trenches)
    ghx.setHorizontalSpacingBetweenPipes(trench_spacing_ft * 0.3048)
    ghx.setPipeInnerDiameter(pipe_id_in * 0.0254)
    ghx.setPipeOuterDiameter(pipe_od_in * 0.0254)
    ghx.setBurialDepth(burial_depth_ft * 0.3048)
    ghx.setSoilThermalConductivity(k_si)
    ghx.setSoilDensity(rho_si)
    ghx.setSoilSpecificHeat(cp_si)
    ghx.setPipeThermalConductivity(0.39)
    ghx.setPipeDensity(950.0)
    ghx.setPipeSpecificHeat(1900.0)
    ghx.setSoilMoistureContentPercent(soil_moisture_pct)
    ghx.setSoilMoistureContentPercentatSaturation(soil_moisture_sat_pct)
    gtm = OpenStudio::Model::SiteGroundTemperatureUndisturbedKusudaAchenbach.new(model)
    gtm.setName("#{loop_name} Kusuda-Achenbach Ground Temperature")
    gtm.setSoilThermalConductivity(k_si)
    gtm.setSoilDensity(rho_si)
    gtm.setSoilSpecificHeat(cp_si)
    gtm.setAverageSoilSurfaceTemperature(f2c.call(ground_avg_f))
    gtm.setAverageAmplitudeofSurfaceTemperature(ground_amp_f / 1.8)
    gtm.setPhaseShiftofMinimumSurfaceTemperature(ground_phase_days)
    old_gtm = ghx.undisturbedGroundTemperatureModel
    ghx.setUndisturbedGroundTemperatureModel(gtm)
    old_gtm.remove if old_gtm.handle != gtm.handle
    gl.addSupplyBranchForComponent(ghx)

    sch = OpenStudio::Model::ScheduleConstant.new(model)
    sch.setName("#{loop_name} Passive Setpoint")
    sch.setValue(f2c.call(loop_setpoint_f))
    gl_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, sch)
    gl_spm.setName("#{loop_name} Setpoint (passive)")
    gl_spm.addToNode(gl.supplyOutletNode)

    unless gl.addDemandBranchForComponent(hp)
      runner.registerError("Could not connect the source side of '#{hp_name}' to '#{loop_name}'.")
      return false
    end
    if hp.respond_to?(:condenserType) && hp.condenserType != 'WaterSource'
      runner.registerError("'#{hp_name}' is still #{hp.condenserType} after connecting its source side.")
      return false
    end

    pipe_ft = n_trenches * trench_length_ft
    runner.registerInfo("Ground loop: #{gl.fluidType}#{glycol_pct > 0 ? " #{glycol_pct.round}%" : ''}, design flow #{(flow / gpm).round(1)} gpm, #{pipe_ft.round} ft of pipe.")
    runner.registerFinalCondition("Connected the source side of '#{hp_name}' to '#{loop_name}': #{n_trenches} x #{trench_length_ft.round(1)} ft horizontal trenches at #{burial_depth_ft.round(2)} ft depth, #{pump_hp.round(2)} hp constant-speed pump, #{(flow / gpm).round(1)} gpm.")
    true
    # --- end user logic ---
    return true
  end
end

AddHorizontalTrenchGroundLoop.new.registerWithApplication
