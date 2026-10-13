class CreateAirToWaterHeatPump < OpenStudio::Measure::ModelMeasure
  def name
    return "Create Air To Water Heat Pump"
  end

  def description
    return "Creates an air-to-water heat pump for heating (HeatPump:PlantLoop:EIR:Heating, air source) from a few catalog values: capacity and COP at one rating point, water flow, and the low-ambient lockout. Performance curves are generated from a Carnot model calibrated to that rating point, so no manufacturer curve data is needed. Defaults represent a ClimaCool UCA modular air-to-water heat pump bank. The heat pump is created on its own, not connected to any plant loop: it is not simulated until it is added to the supply side of a hot water loop, by hand in the OpenStudio Application or by another measure. To add by hand, drag the object onto a plant loop from the My Model tab."
  end

  def modeler_description
    return "Adds an unconnected HeatPumpPlantLoopEIRHeating (CondenserType AirSource, ControlType Setpoint) with Timed or no defrost. CapFT is linear in leaving load water temperature (LLT) and outdoor air temperature (OAT): 1 + a(OAT - OAT_rated) + b(LLT - LLT_rated), with a and b entered in percent per deg F. EIRFT is a biquadratic least-squares fit, over a 13 x 13 grid spanning the curve limits, of EIR/EIR_rated = COP_c,rated / COP_c, where COP_c = Tc / (Tc - Te), Tc = LLT + condenser approach and Te = OAT - evaporator approach (K). Both curves take x = LLT and y = OAT in deg C and equal 1.0 at the rating point, so the reference capacity and COP are reproduced there. The second-law efficiency (COP_rated / COP_c,rated) is reported. Either curve can be replaced by entering six biquadratic coefficients. The EIRfPLR curve is the OpenStudio default. No plant loop, setpoint manager or operation scheme is created or changed."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    hp_name = OpenStudio::Measure::OSArgument.makeStringArgument("hp_name", true)
    hp_name.setDisplayName("Heat pump name")
    hp_name.setDescription("Name of the new heat pump. Must not match an existing HeatPump:PlantLoop:EIR:Heating.")
    hp_name.setDefaultValue("Air-to-Water Heat Pump")
    args << hp_name
    capacity_mbh = OpenStudio::Measure::OSArgument.makeDoubleArgument("capacity_mbh", true)
    capacity_mbh.setDisplayName("Rated heating capacity (MBH)")
    capacity_mbh.setDescription("Heating capacity at the rating point, kBtu/h. Default: 4 x ClimaCool UCA030 at 19F OA / 113F leaving water.")
    capacity_mbh.setDefaultValue(937.6)
    args << capacity_mbh
    cop = OpenStudio::Measure::OSArgument.makeDoubleArgument("cop", true)
    cop.setDisplayName("Rated COP")
    cop.setDescription("Heating COP at the rating point, compressor and fans included.")
    cop.setDefaultValue(2.191)
    args << cop
    rated_oat_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("rated_oat_f", true)
    rated_oat_f.setDisplayName("Rating outdoor air temperature (F)")
    rated_oat_f.setDescription("Outdoor dry-bulb at which capacity and COP are rated, deg F.")
    rated_oat_f.setDefaultValue(19.0)
    args << rated_oat_f
    rated_lwt_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("rated_lwt_f", true)
    rated_lwt_f.setDisplayName("Rating leaving water temperature (F)")
    rated_lwt_f.setDescription("Leaving hot water temperature at which capacity and COP are rated, deg F.")
    rated_lwt_f.setDefaultValue(113.0)
    args << rated_lwt_f
    load_flow_gpm = OpenStudio::Measure::OSArgument.makeDoubleArgument("load_flow_gpm", true)
    load_flow_gpm.setDisplayName("Hot water flow (gpm)")
    load_flow_gpm.setDescription("Design water flow through the heat pump, gpm.")
    load_flow_gpm.setDefaultValue(150.3)
    args << load_flow_gpm
    cap_pct_per_f_oat = OpenStudio::Measure::OSArgument.makeDoubleArgument("cap_pct_per_f_oat", true)
    cap_pct_per_f_oat.setDisplayName("Capacity change per F outdoor air (%/F)")
    cap_pct_per_f_oat.setDescription("Percent change in heating capacity per deg F rise in outdoor air temperature. Positive: more capacity in milder weather.")
    cap_pct_per_f_oat.setDefaultValue(1.17)
    args << cap_pct_per_f_oat
    cap_pct_per_f_lwt = OpenStudio::Measure::OSArgument.makeDoubleArgument("cap_pct_per_f_lwt", true)
    cap_pct_per_f_lwt.setDisplayName("Capacity change per F leaving water (%/F)")
    cap_pct_per_f_lwt.setDescription("Percent change in heating capacity per deg F rise in leaving water temperature. Usually negative.")
    cap_pct_per_f_lwt.setDefaultValue(-0.3)
    args << cap_pct_per_f_lwt
    cond_approach_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("cond_approach_f", true)
    cond_approach_f.setDisplayName("Condenser approach (F)")
    cond_approach_f.setDescription("Refrigerant condensing temperature above the leaving water temperature, deg F, used in the Carnot model.")
    cond_approach_f.setDefaultValue(5.4)
    args << cond_approach_f
    evap_approach_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("evap_approach_f", true)
    evap_approach_f.setDisplayName("Evaporator approach (F)")
    evap_approach_f.setDescription("Refrigerant evaporating temperature below the outdoor air temperature, deg F, used in the Carnot model.")
    evap_approach_f.setDefaultValue(10.8)
    args << evap_approach_f
    min_oat_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("min_oat_f", true)
    min_oat_f.setDisplayName("Low-ambient lockout (F)")
    min_oat_f.setDescription("The heat pump does not run below this outdoor air temperature, deg F.")
    min_oat_f.setDefaultValue(0.0)
    args << min_oat_f
    defrost_control_choices = OpenStudio::StringVector.new
    defrost_control_choices << "Timed"
    defrost_control_choices << "None"
    defrost_control = OpenStudio::Measure::OSArgument.makeChoiceArgument("defrost_control", defrost_control_choices, defrost_control_choices, true)
    defrost_control.setDisplayName("Defrost control")
    defrost_control.setDescription("Timed: a fixed fraction of each hour is spent defrosting when the outdoor air is below the defrost temperature. None: no defrost penalty.")
    defrost_control.setDefaultValue("Timed")
    args << defrost_control
    defrost_max_oat_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("defrost_max_oat_f", true)
    defrost_max_oat_f.setDisplayName("Defrost below outdoor air temperature (F)")
    defrost_max_oat_f.setDescription("Defrost is active below this outdoor air temperature, deg F.")
    defrost_max_oat_f.setDefaultValue(40.0)
    args << defrost_max_oat_f
    defrost_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument("defrost_fraction", true)
    defrost_fraction.setDisplayName("Defrost time fraction")
    defrost_fraction.setDescription("Fraction of each hour spent in defrost, 0 to 1 (EnergyPlus default 0.058333, 3.5 minutes per hour).")
    defrost_fraction.setDefaultValue(0.058333)
    args << defrost_fraction
    lwt_min_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("lwt_min_f", true)
    lwt_min_f.setDisplayName("Curve minimum leaving water temperature (F)")
    lwt_min_f.setDescription("Lower limit of the curves' leaving water temperature input, and of the fit range, deg F.")
    lwt_min_f.setDefaultValue(86.0)
    args << lwt_min_f
    lwt_max_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("lwt_max_f", true)
    lwt_max_f.setDisplayName("Curve maximum leaving water temperature (F)")
    lwt_max_f.setDescription("Upper limit of the curves' leaving water temperature input, and of the fit range, deg F.")
    lwt_max_f.setDefaultValue(140.0)
    args << lwt_max_f
    oat_min_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("oat_min_f", true)
    oat_min_f.setDisplayName("Curve minimum outdoor air temperature (F)")
    oat_min_f.setDescription("Lower limit of the curves' outdoor air temperature input, and of the fit range, deg F.")
    oat_min_f.setDefaultValue(-6.0)
    args << oat_min_f
    oat_max_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("oat_max_f", true)
    oat_max_f.setDisplayName("Curve maximum outdoor air temperature (F)")
    oat_max_f.setDescription("Upper limit of the curves' outdoor air temperature input, and of the fit range, deg F.")
    oat_max_f.setDefaultValue(66.0)
    args << oat_max_f
    capft_override = OpenStudio::Measure::OSArgument.makeStringArgument("capft_override", false)
    capft_override.setDisplayName("CapFT coefficients (optional)")
    capft_override.setDescription("Leave blank to use the generated curve. Otherwise six comma-separated biquadratic coefficients c1..c6 for f(LLT C, OAT C), normalized to 1.0 at the rating point.")
    capft_override.setDefaultValue("")
    args << capft_override
    eirft_override = OpenStudio::Measure::OSArgument.makeStringArgument("eirft_override", false)
    eirft_override.setDisplayName("EIRFT coefficients (optional)")
    eirft_override.setDescription("Leave blank to use the generated Carnot curve. Otherwise six comma-separated biquadratic coefficients c1..c6 for f(LLT C, OAT C), normalized to 1.0 at the rating point.")
    eirft_override.setDefaultValue("")
    args << eirft_override
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
    rated_oat_f = runner.getDoubleArgumentValue("rated_oat_f", user_arguments)
    rated_lwt_f = runner.getDoubleArgumentValue("rated_lwt_f", user_arguments)
    load_flow_gpm = runner.getDoubleArgumentValue("load_flow_gpm", user_arguments)
    cap_pct_per_f_oat = runner.getDoubleArgumentValue("cap_pct_per_f_oat", user_arguments)
    cap_pct_per_f_lwt = runner.getDoubleArgumentValue("cap_pct_per_f_lwt", user_arguments)
    cond_approach_f = runner.getDoubleArgumentValue("cond_approach_f", user_arguments)
    evap_approach_f = runner.getDoubleArgumentValue("evap_approach_f", user_arguments)
    min_oat_f = runner.getDoubleArgumentValue("min_oat_f", user_arguments)
    defrost_control = runner.getStringArgumentValue("defrost_control", user_arguments)
    defrost_max_oat_f = runner.getDoubleArgumentValue("defrost_max_oat_f", user_arguments)
    defrost_fraction = runner.getDoubleArgumentValue("defrost_fraction", user_arguments)
    lwt_min_f = runner.getDoubleArgumentValue("lwt_min_f", user_arguments)
    lwt_max_f = runner.getDoubleArgumentValue("lwt_max_f", user_arguments)
    oat_min_f = runner.getDoubleArgumentValue("oat_min_f", user_arguments)
    oat_max_f = runner.getDoubleArgumentValue("oat_max_f", user_arguments)
    capft_override = runner.getStringArgumentValue("capft_override", user_arguments)
    eirft_override = runner.getStringArgumentValue("eirft_override", user_arguments)
    # --- begin user logic ---
    f2c = lambda { |f| (f - 32.0) / 1.8 }
    if model.getHeatPumpPlantLoopEIRHeatings.any? { |h| h.name.to_s == hp_name }
      runner.registerError("A heat pump named '#{hp_name}' already exists.")
      return false
    end
    if capacity_mbh <= 0 || cop <= 0 || load_flow_gpm <= 0
      runner.registerError('Capacity, COP and water flow must be greater than zero.')
      return false
    end
    if lwt_max_f <= lwt_min_f || oat_max_f <= oat_min_f
      runner.registerError('Each curve maximum must be greater than its minimum.')
      return false
    end
    unless rated_lwt_f.between?(lwt_min_f, lwt_max_f) && rated_oat_f.between?(oat_min_f, oat_max_f)
      runner.registerError("The rating point (#{rated_oat_f}F OA, #{rated_lwt_f}F water) must lie inside the curve limits.")
      return false
    end
    runner.registerInitialCondition("The model has #{model.getHeatPumpPlantLoopEIRHeatings.size} plant loop heating heat pumps.")

    bq = lambda { |x, y| [1.0, x, x * x, y, y * y, x * y] }
    bq_eval = lambda { |co, x, y| bq.call(x, y).zip(co).sum { |a, b| a * b } }
    parse = lambda do |label, csv|
      co = csv.to_s.split(',').map { |s| Float(s.strip) rescue nil }
      return co if co.size == 6 && co.none?(&:nil?)
      runner.registerError("#{label} must be six comma-separated numbers.")
      nil
    end
    llt_r = f2c.call(rated_lwt_f)
    oat_r = f2c.call(rated_oat_f)

    # CapFT: linear in LLT and OAT, 1.0 at the rating point.
    if capft_override.to_s.strip.empty?
      a_oat = cap_pct_per_f_oat / 100.0 * 1.8
      a_llt = cap_pct_per_f_lwt / 100.0 * 1.8
      cap_co = [1.0 - a_llt * llt_r - a_oat * oat_r, a_llt, 0.0, a_oat, 0.0, 0.0]
      cap_src = 'linear'
    else
      cap_co = parse.call('CapFT coefficients', capft_override)
      return false if cap_co.nil?
      cap_src = 'entered'
    end

    # EIRFT: Carnot COP with refrigerant approaches, least-squares biquadratic fit.
    if eirft_override.to_s.strip.empty?
      k = lambda { |f| f2c.call(f) + 273.15 }
      carnot = lambda do |llt_f, oat_f|
        tc = k.call(llt_f) + cond_approach_f / 1.8
        te = k.call(oat_f) - evap_approach_f / 1.8
        tc > te ? tc / (tc - te) : nil
      end
      cop_c_r = carnot.call(rated_lwt_f, rated_oat_f)
      n = 13
      rows = []
      zs = []
      n.times do |i|
        n.times do |j|
          l = lwt_min_f + (lwt_max_f - lwt_min_f) * i / (n - 1)
          o = oat_min_f + (oat_max_f - oat_min_f) * j / (n - 1)
          cc = carnot.call(l, o)
          if cc.nil?
            runner.registerError("Condensing temperature is not above evaporating temperature at #{l.round(1)}F water / #{o.round(1)}F OA; narrow the curve limits or reduce the approaches.")
            return false
          end
          rows << bq.call(f2c.call(l), f2c.call(o))
          zs << cop_c_r / cc
        end
      end
      # Normal equations, solved by Gaussian elimination with partial pivoting.
      ata = Array.new(6) { |r| Array.new(6) { |c| rows.sum { |row| row[r] * row[c] } } }
      atz = Array.new(6) { |r| rows.each_with_index.sum { |row, idx| row[r] * zs[idx] } }
      6.times do |p|
        piv = (p...6).max_by { |r| ata[r][p].abs }
        ata[p], ata[piv] = ata[piv], ata[p]
        atz[p], atz[piv] = atz[piv], atz[p]
        ((p + 1)...6).each do |r|
          f = ata[r][p] / ata[p][p]
          (p...6).each { |c| ata[r][c] -= f * ata[p][c] }
          atz[r] -= f * atz[p]
        end
      end
      eir_co = Array.new(6, 0.0)
      5.downto(0) { |r| eir_co[r] = (atz[r] - ((r + 1)...6).sum { |c| ata[r][c] * eir_co[c] }) / ata[r][r] }
      norm = bq_eval.call(eir_co, llt_r, oat_r)
      eir_co = eir_co.map { |c| c / norm }
      max_err = rows.each_with_index.map { |row, idx| (row.zip(eir_co).sum { |a, b| a * b } / zs[idx] - 1.0).abs }.max
      runner.registerInfo("Carnot model: second-law efficiency #{(cop / cop_c_r).round(4)}; EIRFT fit max error #{(max_err * 100).round(2)}% over the curve limits.")
      eir_src = 'Carnot fit'
    else
      eir_co = parse.call('EIRFT coefficients', eirft_override)
      return false if eir_co.nil?
      eir_src = 'entered'
    end
    [['CapFT', cap_co], ['EIRFT', eir_co]].each do |label, co|
      v = bq_eval.call(co, llt_r, oat_r)
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
      cv.setMinimumValueofy(f2c.call(oat_min_f))
      cv.setMaximumValueofy(f2c.call(oat_max_f))
      cv
    end

    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    hp.setName(hp_name)
    hp.setCondenserType('AirSource')
    hp.setReferenceCapacity(capacity_mbh * 1000.0 / 3.412142)
    hp.setReferenceCoefficientofPerformance(cop)
    hp.setLoadSideReferenceFlowRate(load_flow_gpm * 6.30902e-5)
    hp.setControlType('Setpoint')
    hp.setMinimumSourceInletTemperature(f2c.call(min_oat_f))
    hp.setHeatPumpDefrostControl(defrost_control)
    if defrost_control == 'Timed'
      hp.setHeatPumpDefrostTimePeriodFraction(defrost_fraction)
      hp.setMaximumOutdoorDryBulbTemperatureForDefrostOperation(f2c.call(defrost_max_oat_f))
    end
    old_cap = hp.capacityModifierFunctionofTemperatureCurve
    old_eir = hp.electricInputtoOutputRatioModifierFunctionofTemperatureCurve
    hp.setCapacityModifierFunctionofTemperatureCurve(mk_curve.call("#{hp_name} CapFT", cap_co))
    hp.setElectricInputtoOutputRatioModifierFunctionofTemperatureCurve(mk_curve.call("#{hp_name} EIRFT", eir_co))
    [old_cap, old_eir].each { |c| c.remove if c.directUseCount == 0 }
    runner.registerInfo("CapFT (#{cap_src}): #{cap_co.map { |c| format('%.8e', c) }.join(',')}")
    runner.registerInfo("EIRFT (#{eir_src}): #{eir_co.map { |c| format('%.8e', c) }.join(',')}")

    runner.registerFinalCondition("Created '#{hp_name}': #{capacity_mbh} MBH, COP #{cop} at #{rated_oat_f}F OA / #{rated_lwt_f}F water, lockout below #{min_oat_f}F OA. It is not connected to a plant loop and will not be simulated until it is added to a hot water loop's supply side.")
    true
    # --- end user logic ---
    return true
  end
end

CreateAirToWaterHeatPump.new.registerWithApplication
