class CreateWaterToWaterHeatPump < OpenStudio::Measure::ModelMeasure
  INTENDED_TYPE = 'IntendedCondenserType'

  def name
    return "Create Water To Water Heat Pump"
  end

  def description
    return "Creates a water-to-water heat pump for heating (HeatPump:PlantLoop:EIR:Heating, water source) from catalog values: capacity and COP at one rating point, load and source water flows, and the minimum entering source temperature. Performance curves are entered as biquadratic coefficients; the defaults are fitted to the WaterFurnace Envision2 NXW600 heating table. The heat pump is created on its own, not connected to any plant loop: it is not simulated until its load side is added to the supply side of a hot water loop and its source side to the demand side of a condenser loop, by hand in the OpenStudio Application or by other measures such as Add Horizontal Trench Ground Loop and Add Heat Pump Ahead Of Boiler. To add by hand, drag the object onto each loop from the My Model tab. Until its source side is on a loop, OpenStudio shows it as air source; connecting the source side makes it water source."
  end

  def modeler_description
    return "Adds an unconnected HeatPumpPlantLoopEIRHeating with ControlType Setpoint. OpenStudio only allows CondenserType WaterSource once the source side is on a plant loop, so the heat pump keeps the default AirSource until then; the intended type is recorded in the object's AdditionalProperties (IntendedCondenserType = WaterSource), which Add Horizontal Trench Ground Loop and Add Heat Pump Ahead Of Boiler read. CapFT and EIRFT are biquadratics in x = leaving load water temperature (LLT, deg C) and y = entering source temperature (EST, deg C), limited to the entered ranges. The rating point is given as entering load temperature; LLT there = ELT + capacity / (500 x load gpm). Each curve is checked against 1.0 at (LLT, EST) and a warning is given if it is off by more than 0.5%. The default coefficients were fitted to the Envision2 NXW600 heating table (100 gpm load / 200 gpm source) and normalized at EST 45F / ELT 100F. The EIRfPLR curve is the OpenStudio default (constant 1.0). No plant loop, setpoint manager or operation scheme is created or changed. The maximum leaving water temperature is stored as the MaximumSupplyWaterTemperatureCurve, a Table:Lookup of entering source temperature (deg C): linear between the entered points, constant beyond them. EnergyPlus 25.2 evaluates that curve at the outdoor dry-bulb rather than the source temperature, and does not hold the outlet to it (tested: with a 105F curve and a 113F setpoint the heat pump delivered 113F); Add Heat Pump Ahead Of Boiler reads it at the heat pump's source inlet temperature and limits the heat pump's setpoint to it, which is what enforces it. MinimumPartLoadRatio is set from the smallest capacity step; below it EnergyPlus cycles the heat pump."
  end

  # Parses "x:y, x:y" (deg F) into [[x, y], ...] sorted by x, or nil.
  def parse_points(text)
    pts = text.to_s.split(',').map do |pair|
      xy = pair.split(':').map { |v| Float(v.strip) rescue nil }
      return nil unless xy.size == 2 && xy.none?(&:nil?)
      xy
    end
    return nil if pts.empty? || pts.map(&:first).uniq.size != pts.size
    pts.sort_by(&:first)
  end

  # Maximum Supply Water Temperature as a Table:Lookup of entering source
  # temperature in deg C: linear between the points, constant beyond the end
  # points. One point gives a constant. Note: EnergyPlus 25.2 evaluates this
  # curve at the outdoor dry-bulb, not the source temperature.
  def max_supply_table(model, name, pts_c)
    pts_c = [pts_c[0], [pts_c[0][0] + 1.0, pts_c[0][1]]] if pts_c.size == 1
    iv = OpenStudio::Model::TableIndependentVariable.new(model)
    iv.setName("#{name} Entering Source Temperature")
    iv.setInterpolationMethod('Linear')
    iv.setExtrapolationMethod('Constant')
    iv.setUnitType('Temperature')
    iv.setMinimumValue(-60.0)
    iv.setMaximumValue(80.0)
    iv.setValues(pts_c.map(&:first))
    t = OpenStudio::Model::TableLookup.new(model)
    t.setName(name)
    t.addIndependentVariable(iv)
    t.setOutputValues(pts_c.map(&:last))
    t.setMinimumOutput(pts_c.map(&:last).min)
    t.setMaximumOutput(pts_c.map(&:last).max)
    t
  end

  # Linear between points, constant beyond them.
  def interp(pts, x)
    return pts.first[1] if x <= pts.first[0]
    return pts.last[1] if x >= pts.last[0]
    a, b = pts.each_cons(2).find { |_, q| x <= q[0] }
    a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    hp_name = OpenStudio::Measure::OSArgument.makeStringArgument("hp_name", true)
    hp_name.setDisplayName("Heat pump name")
    hp_name.setDescription("Name of the new heat pump. Must not match an existing HeatPump:PlantLoop:EIR:Heating.")
    hp_name.setDefaultValue("Water-to-Water Heat Pump")
    args << hp_name
    capacity_mbh = OpenStudio::Measure::OSArgument.makeDoubleArgument("capacity_mbh", true)
    capacity_mbh.setDisplayName("Rated heating capacity (MBH)")
    capacity_mbh.setDescription("Heating capacity at the rating point, kBtu/h. Default: WaterFurnace Envision2 NXW600 at 45F EST / 100F ELT.")
    capacity_mbh.setDefaultValue(617.8)
    args << capacity_mbh
    cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("cop", true)
    cop.setDisplayName("Rated COP")
    cop.setDescription("Heating COP at the rating point.")
    cop.setDefaultValue(3.575)
    args << cop
    rated_est_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("rated_est_f", true)
    rated_est_f.setDisplayName("Rating entering source temperature (F)")
    rated_est_f.setDescription("Entering source (ground loop) water temperature at which capacity and COP are rated, deg F.")
    rated_est_f.setDefaultValue(45.0)
    args << rated_est_f
    rated_elt_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("rated_elt_f", true)
    rated_elt_f.setDisplayName("Rating entering load temperature (F)")
    rated_elt_f.setDescription("Entering load (hot water) temperature at which capacity and COP are rated, deg F, as listed in the catalog.")
    rated_elt_f.setDefaultValue(100.0)
    args << rated_elt_f
    load_flow_gpm = OpenStudio::Measure::OSArgument.makeDoubleArgument("load_flow_gpm", true)
    load_flow_gpm.setDisplayName("Load side flow (gpm)")
    load_flow_gpm.setDescription("Hot water flow through the heat pump, gpm.")
    load_flow_gpm.setDefaultValue(100.0)
    args << load_flow_gpm
    source_flow_gpm = OpenStudio::Measure::OSArgument.makeDoubleArgument("source_flow_gpm", true)
    source_flow_gpm.setDisplayName("Source side flow (gpm)")
    source_flow_gpm.setDescription("Source (ground loop) flow through the heat pump, gpm.")
    source_flow_gpm.setDefaultValue(200.0)
    args << source_flow_gpm
    min_est_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("min_est_f", true)
    min_est_f.setDisplayName("Minimum entering source temperature (F)")
    min_est_f.setDescription("The heat pump does not run below this entering source temperature, deg F. 25F assumes an antifreeze solution in the source loop; use about 40F for plain water.")
    min_est_f.setDefaultValue(25.0)
    args << min_est_f
    max_supply_points = OpenStudio::Measure::OSArgument.makeStringArgument("max_supply_points", true)
    max_supply_points.setDisplayName("Maximum leaving load water temperature vs entering source (F)")
    max_supply_points.setDescription("Highest water temperature the heat pump can deliver, as comma-separated entering source:leaving load water pairs in deg F, from the manufacturer's data. Linear between points, constant beyond the end points; one pair gives a constant. Stored as the heat pump's Maximum Supply Water Temperature Curve (a Table:Lookup); Add Heat Pump Ahead Of Boiler uses it to limit the heat pump's setpoint. Default: Envision2 NXW600 heating table at 100 gpm load / 200 gpm source, leaving load water at the highest allowed entering load water (120F at EST 30-70F, 100F at EST 90F).")
    max_supply_points.setDefaultValue("30:129.4, 50:132.3, 70:135.2, 90:118.8")
    args << max_supply_points
    min_plr = OpenStudio::Measure::OSArgument.makeDoubleArgument("min_plr", true)
    min_plr.setDisplayName("Minimum part load ratio")
    min_plr.setDescription("Smallest capacity step as a fraction of full capacity; below it the heat pump cycles. Default: one NXW600 with 2 compressors, 0.5.")
    min_plr.setDefaultValue(0.5)
    args << min_plr
    lwt_min_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("lwt_min_f", true)
    lwt_min_f.setDisplayName("Curve minimum leaving load temperature (F)")
    lwt_min_f.setDescription("Lower limit of the curves' leaving load water temperature input, deg F.")
    lwt_min_f.setDefaultValue(68.0)
    args << lwt_min_f
    lwt_max_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("lwt_max_f", true)
    lwt_max_f.setDisplayName("Curve maximum leaving load temperature (F)")
    lwt_max_f.setDescription("Upper limit of the curves' leaving load water temperature input, deg F.")
    lwt_max_f.setDefaultValue(136.4)
    args << lwt_max_f
    est_min_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("est_min_f", true)
    est_min_f.setDisplayName("Curve minimum entering source temperature (F)")
    est_min_f.setDescription("Lower limit of the curves' entering source temperature input, deg F.")
    est_min_f.setDefaultValue(23.0)
    args << est_min_f
    est_max_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("est_max_f", true)
    est_max_f.setDisplayName("Curve maximum entering source temperature (F)")
    est_max_f.setDescription("Upper limit of the curves' entering source temperature input, deg F.")
    est_max_f.setDefaultValue(91.4)
    args << est_max_f
    capft_coeffs = OpenStudio::Measure::OSArgument.makeStringArgument("capft_coeffs", true)
    capft_coeffs.setDisplayName("CapFT coefficients")
    capft_coeffs.setDescription("Six comma-separated biquadratic coefficients c1..c6 for f(LLT C, EST C), normalized to 1.0 at the rating point. Default: Envision2 NXW600 fit.")
    capft_coeffs.setDefaultValue("1.11556398e+00,-6.08372478e-03,5.02650607e-08,2.01759444e-02,-4.58017470e-06,3.26046798e-05")
    args << capft_coeffs
    eirft_coeffs = OpenStudio::Measure::OSArgument.makeStringArgument("eirft_coeffs", true)
    eirft_coeffs.setDisplayName("EIRFT coefficients")
    eirft_coeffs.setDescription("Six comma-separated biquadratic coefficients c1..c6 for f(LLT C, EST C), normalized to 1.0 at the rating point. Default: Envision2 NXW600 fit.")
    eirft_coeffs.setDefaultValue("2.09374459e-01,1.68837837e-02,8.22373320e-05,-1.45115593e-03,2.02688268e-04,-3.94876566e-04")
    args << eirft_coeffs
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    hp_name = runner.getStringArgumentValue("hp_name", user_arguments)
    capacity_mbh = runner.getDoubleArgumentValue("capacity_mbh", user_arguments)
    cop = runner.getDoubleArgumentValue("cop", user_arguments)
    rated_est_f = runner.getDoubleArgumentValue("rated_est_f", user_arguments)
    rated_elt_f = runner.getDoubleArgumentValue("rated_elt_f", user_arguments)
    load_flow_gpm = runner.getDoubleArgumentValue("load_flow_gpm", user_arguments)
    source_flow_gpm = runner.getDoubleArgumentValue("source_flow_gpm", user_arguments)
    min_est_f = runner.getDoubleArgumentValue("min_est_f", user_arguments)
    max_supply_points = runner.getStringArgumentValue("max_supply_points", user_arguments)
    min_plr = runner.getDoubleArgumentValue("min_plr", user_arguments)
    lwt_min_f = runner.getDoubleArgumentValue("lwt_min_f", user_arguments)
    lwt_max_f = runner.getDoubleArgumentValue("lwt_max_f", user_arguments)
    est_min_f = runner.getDoubleArgumentValue("est_min_f", user_arguments)
    est_max_f = runner.getDoubleArgumentValue("est_max_f", user_arguments)
    capft_coeffs = runner.getStringArgumentValue("capft_coeffs", user_arguments)
    eirft_coeffs = runner.getStringArgumentValue("eirft_coeffs", user_arguments)
    # --- begin user logic ---
    f2c = lambda { |f| (f - 32.0) / 1.8 }
    if model.getHeatPumpPlantLoopEIRHeatings.any? { |h| h.name.to_s == hp_name }
      runner.registerError("A heat pump named '#{hp_name}' already exists.")
      return false
    end
    if capacity_mbh <= 0 || cop <= 0 || load_flow_gpm <= 0 || source_flow_gpm <= 0
      runner.registerError('Capacity, COP and both water flows must be greater than zero.')
      return false
    end
    if lwt_max_f <= lwt_min_f || est_max_f <= est_min_f
      runner.registerError('Each curve maximum must be greater than its minimum.')
      return false
    end
    rated_llt_f = rated_elt_f + capacity_mbh * 1000.0 / (500.0 * load_flow_gpm)
    unless rated_llt_f.between?(lwt_min_f, lwt_max_f) && rated_est_f.between?(est_min_f, est_max_f)
      runner.registerError("The rating point (#{rated_est_f}F EST, #{rated_llt_f.round(1)}F leaving load water) must lie inside the curve limits.")
      return false
    end
    max_pts = parse_points(max_supply_points)
    if max_pts.nil?
      runner.registerError("Maximum leaving load water temperature must be comma-separated entering source:leaving load water pairs in deg F with distinct source temperatures, for example 30:129.4, 50:132.3, 70:135.2, 90:118.8.")
      return false
    end
    if interp(max_pts, rated_est_f) < rated_llt_f - 0.05
      runner.registerError("The maximum leaving load water temperature at the rating entering source temperature (#{interp(max_pts, rated_est_f).round(1)}F at #{rated_est_f}F) is below the rated leaving load water temperature (#{rated_llt_f.round(1)}F).")
      return false
    end
    if max_pts.map(&:last).max > lwt_max_f
      runner.registerWarning("The maximum leaving load water temperature (up to #{max_pts.map(&:last).max}F) is above the curves' maximum (#{lwt_max_f}F); above #{lwt_max_f}F EnergyPlus holds capacity and COP at their #{lwt_max_f}F values.")
    end
    unless min_plr.between?(0.0, 1.0)
      runner.registerError('Minimum part load ratio must be between 0 and 1.')
      return false
    end
    runner.registerInitialCondition("The model has #{model.getHeatPumpPlantLoopEIRHeatings.size} plant loop heating heat pumps.")

    bq_eval = lambda { |co, x, y| [1.0, x, x * x, y, y * y, x * y].zip(co).sum { |a, b| a * b } }
    parse = lambda do |label, csv|
      co = csv.to_s.split(',').map { |s| Float(s.strip) rescue nil }
      return co if co.size == 6 && co.none?(&:nil?)
      runner.registerError("#{label} must be six comma-separated numbers.")
      nil
    end
    cap_co = parse.call('CapFT coefficients', capft_coeffs)
    return false if cap_co.nil?
    eir_co = parse.call('EIRFT coefficients', eirft_coeffs)
    return false if eir_co.nil?
    [['CapFT', cap_co], ['EIRFT', eir_co]].each do |label, co|
      v = bq_eval.call(co, f2c.call(rated_llt_f), f2c.call(rated_est_f))
      runner.registerWarning("#{label} equals #{v.round(4)} at the rating point, not 1.0; the rated capacity and COP will not be reproduced there.") if (v - 1.0).abs > 0.005
    end

    mk_curve = lambda do |name, co|
      cv = OpenStudio::Model::CurveBiquadratic.new(model)
      cv.setName(name)
      cv.setCoefficient1Constant(co[0])
      cv.setCoefficient2x(co[1])
      cv.setCoefficient3xPOW2(co[2])
      cv.setCoefficient4y(co[3])
      cv.setCoefficient5yPOW2(co[4])
      cv.setCoefficient6xTIMESY(co[5])
      cv.setMinimumValueofx(f2c.call(lwt_min_f))
      cv.setMaximumValueofx(f2c.call(lwt_max_f))
      cv.setMinimumValueofy(f2c.call(est_min_f))
      cv.setMaximumValueofy(f2c.call(est_max_f))
      cv
    end

    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    hp.setName(hp_name)
    hp.setReferenceCapacity(capacity_mbh * 1000.0 / 3.412142)
    hp.setReferenceCoefficientofPerformance(cop)
    hp.setLoadSideReferenceFlowRate(load_flow_gpm * 6.30902e-5)
    hp.setSourceSideReferenceFlowRate(source_flow_gpm * 6.30902e-5)
    hp.setControlType('Setpoint')
    hp.setMinimumSourceInletTemperature(f2c.call(min_est_f))
    hp.additionalProperties.setFeature(INTENDED_TYPE, 'WaterSource')
    old_cap = hp.capacityModifierFunctionofTemperatureCurve
    old_eir = hp.electricInputtoOutputRatioModifierFunctionofTemperatureCurve
    hp.setCapacityModifierFunctionofTemperatureCurve(mk_curve.call("#{hp_name} CapFT", cap_co))
    hp.setElectricInputtoOutputRatioModifierFunctionofTemperatureCurve(mk_curve.call("#{hp_name} EIRFT", eir_co))
    [old_cap, old_eir].each { |c| c.remove if c.directUseCount == 0 }
    hp.setMaximumSupplyWaterTemperatureCurve(max_supply_table(model, "#{hp_name} Maximum Supply Water Temperature", max_pts.map { |x, y| [f2c.call(x), f2c.call(y)] }))
    hp.setMinimumPartLoadRatio(min_plr)
    runner.registerInfo("Rating point: #{rated_est_f}F EST, #{rated_elt_f}F entering / #{rated_llt_f.round(1)}F leaving load water.")

    runner.registerFinalCondition("Created '#{hp_name}': #{capacity_mbh} MBH, COP #{cop} at #{rated_est_f}F EST / #{rated_elt_f}F ELT, #{load_flow_gpm} gpm load / #{source_flow_gpm} gpm source, lockout below #{min_est_f}F EST, maximum leaving load water #{max_pts.map { |x, y| "#{y}F at #{x}F" }.join(", ")} EST, minimum part load ratio #{min_plr}. It is not connected to a plant loop: connect its source side to a condenser loop and its load side to a hot water loop before simulating.")
    true
    # --- end user logic ---
    return true
  end
end

CreateWaterToWaterHeatPump.new.registerWithApplication
