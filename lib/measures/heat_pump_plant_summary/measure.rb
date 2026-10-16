require 'erb'

class HeatPumpPlantSummary < OpenStudio::Measure::ReportingMeasure
  def name
    return "Heat Pump Plant Summary"
  end

  def description
    return "Reports how the heating heat pumps and hot water boilers on the model's plant loops performed: annual and monthly heat delivered, electricity and fuel used, seasonal COP and boiler efficiency, each heat pump's share of the plant's heat, and source temperature statistics including the hours at or below a lockout temperature. Covers plant loop EIR, water-to-water equation fit, fuel-fired air-to-water and air-to-water heat pumps. The hourly outputs it needs are requested automatically."
  end

  def modeler_description
    return "Requests hourly output variables for each heating heat pump and boiler on a plant loop in the last OpenStudio model (or, without a model, for every supported type), reads them from the SQL file for the run period and writes report.html plus runner values. Heat pumps: HeatPumpPlantLoopEIRHeating and HeatPumpWaterToWaterEquationFitHeating ('Heat Pump Load Side Heat Transfer Rate', 'Heat Pump Electricity Rate', 'Heat Pump Source Side Inlet Temperature'); HeatPumpAirToWater with a heating mode on a loop (the same names ending ' in Heating Mode'); HeatPumpAirToWaterFuelFiredHeating ('Fuel-fired Absorption HeatPump Load Side Heat Transfer Rate', '... Fuel Rate', '... Electricity Rate', with outdoor air temperature as the source temperature). Boilers: 'Boiler Heating Rate' and 'Boiler <fuel> Rate'. Hourly average rates in W are summed to Wh. COP = heat / electricity; for the fuel-fired heat pump the fuel-based ratio (heat / fuel) is also given. Source temperature statistics cover all hours of the run period. Cooling heat pumps are not reported."
  end

  HP_VARS = {
    'eir' => { q: 'Heat Pump Load Side Heat Transfer Rate', e: 'Heat Pump Electricity Rate', t: 'Heat Pump Source Side Inlet Temperature' },
    'awhp' => { q: 'Heat Pump Load Side Heat Transfer Rate in Heating Mode', e: 'Heat Pump Electricity Rate in Heating Mode', t: 'Heat Pump Source Side Inlet Temperature in Heating Mode' },
    'fuel' => { q: 'Fuel-fired Absorption HeatPump Load Side Heat Transfer Rate', e: 'Fuel-fired Absorption HeatPump Electricity Rate', f: 'Fuel-fired Absorption HeatPump Fuel Rate', t: 'Site Outdoor Air Drybulb Temperature' }
  }
  OAT = 'Site Outdoor Air Drybulb Temperature'

  # Heating heat pumps on a plant loop, as hashes with the output variable set
  # (:vars), the SQL key, and what the source temperature measures.
  def heat_pumps(model)
    hps = []
    model.getHeatPumpPlantLoopEIRHeatings.each do |h|
      next if h.plantLoop.empty?
      hps << { name: h.name.to_s, type: 'HeatPump:PlantLoop:EIR:Heating', vars: 'eir', key: h.name.to_s, source: h.condenserType == 'AirSource' ? 'outdoor air' : 'entering source water' }
    end
    model.getHeatPumpWaterToWaterEquationFitHeatings.each do |h|
      next if h.plantLoop.empty?
      hps << { name: h.name.to_s, type: 'HeatPump:WaterToWater:EquationFit:Heating', vars: 'eir', key: h.name.to_s, source: 'entering source water' }
    end
    model.getHeatPumpAirToWaterFuelFiredHeatings.each do |h|
      next if h.plantLoop.empty?
      hps << { name: h.name.to_s, type: 'HeatPump:AirToWater:FuelFired:Heating', vars: 'fuel', key: h.name.to_s, source: 'outdoor air' }
    end
    model.getHeatPumpAirToWaters.each do |h|
      mode = h.heatingOperationMode
      next if mode.empty? || mode.get.plantLoop.empty?
      hps << { name: h.name.to_s, type: 'HeatPump:AirToWater', vars: 'awhp', key: h.name.to_s, source: 'outdoor air' }
    end
    hps
  end

  def boilers(model)
    model.getBoilerHotWaters.select { |b| b.plantLoop.is_initialized }.map { |b| { name: b.name.to_s, fuel: b.fuelType } }
  end

  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new
    lockout_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("lockout_f", true)
    lockout_f.setDisplayName("Lockout temperature (F)")
    lockout_f.setDescription("Hours with a heat pump's source temperature (entering source water, or outdoor air for air-source units) at or below this value are counted, deg F.")
    lockout_f.setDefaultValue(25.0)
    args << lockout_f
    return args
  end

  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    result = OpenStudio::IdfObjectVector.new
    model = runner.lastOpenStudioModel
    names = []
    if model.is_initialized
      model = model.get
      heat_pumps(model).each { |hp| names.concat(HP_VARS[hp[:vars]].values) }
      boilers(model).each { |b| names << 'Boiler Heating Rate' << "Boiler #{b[:fuel]} Rate" }
    else
      HP_VARS.values.each { |v| names.concat(v.values) }
      names << 'Boiler Heating Rate' << 'Boiler NaturalGas Rate' << 'Boiler Propane Rate'
    end
    names.uniq.each { |n| result << OpenStudio::IdfObject.load("Output:Variable,*,#{n},Hourly;").get }
    return result
  end

  def run(runner, user_arguments)
    super(runner, user_arguments)
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end
    lockout_f = runner.getDoubleArgumentValue("lockout_f", user_arguments)
    model_opt = runner.lastOpenStudioModel
    model = model_opt.is_initialized ? model_opt.get : nil
    sql_opt = runner.lastEnergyPlusSqlFile
    if sql_opt.is_initialized
      sql = sql_opt.get
      model.setSqlFile(sql) if model
    end
    # --- begin user logic ---
    if model.nil? || sql_opt.empty?
      runner.registerError('The model and the simulation results are both needed.')
      return false
    end
    env = sql.availableEnvPeriods.find { |e| e.upcase.include?('RUN PERIOD') }
    if env.nil?
      runner.registerError('The results have no run period.')
      return false
    end
    c2f = lambda { |c| c * 1.8 + 32.0 }
    mmbtu = 3.412142e-3 # per kWh

    # Hourly series as [[month, value], ...], or nil if not in the results.
    series = lambda do |var, key|
      # Component keys are stored in upper case, 'Environment' is not.
      ts = sql.timeSeries(env, 'Hourly', var, key.upcase)
      ts = sql.timeSeries(env, 'Hourly', var, key) if ts.empty?
      next nil if ts.empty?
      ts = ts.get
      vals = ts.values
      dts = ts.dateTimes
      (0...vals.size).map { |i| [dts[i].date.monthOfYear.value, vals[i]] }
    end
    kwh = lambda { |s| s.nil? ? 0.0 : s.sum { |_, w| w } / 1000.0 }
    monthly_kwh = lambda do |s|
      m = Array.new(13, 0.0)
      s&.each { |mo, w| m[mo] += w / 1000.0 }
      m
    end
    ratio = lambda { |a, b| b > 0 ? a / b : nil }
    # Number with thousands separators, or '-' for nil.
    fmt = lambda do |v, d = 0|
      next '-' if v.nil?
      whole, frac = format("%.#{d}f", v).split('.')
      whole = whole.gsub(/(\d)(?=(\d{3})+$)/, '\1,')
      frac ? "#{whole}.#{frac}" : whole
    end

    hp_rows = []
    heat_pumps(model).each do |hp|
      v = HP_VARS[hp[:vars]]
      q = series.call(v[:q], hp[:key])
      if q.nil?
        runner.registerWarning("No hourly results for '#{hp[:name]}' (#{v[:q]}); it is left out. Rerun the simulation with this measure in the workflow so its outputs are requested.")
        next
      end
      e = series.call(v[:e], hp[:key])
      f = v[:f] ? series.call(v[:f], hp[:key]) : nil
      t = v[:t] == OAT ? series.call(OAT, 'Environment') : series.call(v[:t], hp[:key])
      temps = t.nil? ? [] : t.map { |_, c| c2f.call(c) }
      hp_rows << hp.merge(heat: kwh.call(q), elec: kwh.call(e), fuel: f ? kwh.call(f) : nil,
                          run_hours: q.count { |_, w| w > 0 }, mq: monthly_kwh.call(q), me: monthly_kwh.call(e),
                          t_min: temps.min, t_mean: temps.empty? ? nil : temps.sum / temps.size, t_max: temps.max,
                          lockout_hours: temps.count { |x| x <= lockout_f + 0.01 }, has_temps: !temps.empty?)
    end
    boiler_rows = boilers(model).map do |b|
      q = series.call('Boiler Heating Rate', b[:name])
      if q.nil?
        runner.registerWarning("No hourly results for boiler '#{b[:name]}'; it is left out.")
        next nil
      end
      fuel = series.call("Boiler #{b[:fuel]} Rate", b[:name])
      b.merge(heat: kwh.call(q), fuel_kwh: fuel.nil? ? nil : kwh.call(fuel), mq: monthly_kwh.call(q))
    end.compact
    if hp_rows.empty? && boiler_rows.empty?
      runner.registerWarning('No heating heat pumps or boilers with results were found.')
      runner.registerFinalCondition('Nothing to report.')
      return true
    end
    runner.registerInitialCondition("Reporting #{hp_rows.size} heat pumps and #{boiler_rows.size} boilers.")

    hp_heat = hp_rows.sum { |r| r[:heat] }
    hp_elec = hp_rows.sum { |r| r[:elec] }
    b_heat = boiler_rows.sum { |r| r[:heat] }
    plant = hp_heat + b_heat
    hp_rows.each do |r|
      fuel = r[:fuel] ? format(', fuel %.1f MMBtu (heat / fuel %s)', r[:fuel] * mmbtu, fmt.call(ratio.call(r[:heat], r[:fuel]), 2)) : ''
      runner.registerInfo(format("%s: heat %.0f kWh (%.1f MMBtu), electricity %.0f kWh%s, COP %s, %d hours running; source temperature min/mean/max %s/%s/%s F, %d hours at or below %.0f F.",
                                 r[:name], r[:heat], r[:heat] * mmbtu, r[:elec], fuel, fmt.call(ratio.call(r[:heat], r[:elec]), 2), r[:run_hours],
                                 fmt.call(r[:t_min], 1), fmt.call(r[:t_mean], 1), fmt.call(r[:t_max], 1), r[:lockout_hours], lockout_f))
    end
    boiler_rows.each do |r|
      fuel_mmbtu = r[:fuel_kwh].nil? ? nil : r[:fuel_kwh] * mmbtu
      runner.registerInfo(format('%s: heat %.0f kWh (%.1f MMBtu), %s %s MMBtu, efficiency %s.', r[:name], r[:heat], r[:heat] * mmbtu, r[:fuel], fmt.call(fuel_mmbtu, 1), r[:fuel_kwh].nil? ? '-' : fmt.call(ratio.call(r[:heat], r[:fuel_kwh]), 3)))
    end
    runner.registerValue('hp_heat_kwh', hp_heat)
    runner.registerValue('hp_elec_kwh', hp_elec)
    runner.registerValue('hp_cop_seasonal', ratio.call(hp_heat, hp_elec) || 0.0)
    runner.registerValue('boiler_heat_kwh', b_heat)
    runner.registerValue('hp_share_pct', plant > 0 ? 100.0 * hp_heat / plant : 0.0)
    with_t = hp_rows.select { |r| r[:has_temps] }
    unless with_t.empty?
      runner.registerValue('source_temp_min_f', with_t.map { |r| r[:t_min] }.min)
      runner.registerValue('hours_at_lockout', with_t.map { |r| r[:lockout_hours] }.max)
    end

    # HTML report
    esc = lambda { |s| ERB::Util.html_escape(s.to_s) }
    table = lambda do |head, rows, cls = ''|
      h = head.map { |c| "<th>#{esc.call(c)}</th>" }.join
      b = rows.map { |row| '<tr>' + row.map { |c| "<td>#{esc.call(c)}</td>" }.join + '</tr>' }.join("\n")
      "<table class=\"#{cls}\"><thead><tr>#{h}</tr></thead><tbody>\n#{b}\n</tbody></table>"
    end
    share = lambda { |q| plant > 0 ? fmt.call(100.0 * q / plant, 1) + '%' : '-' }
    out = []
    out << '<h1>Heat Pump Plant Summary</h1>'
    out << '<h2>Annual</h2>'
    rows = hp_rows.map do |r|
      [r[:name], r[:type], fmt.call(r[:heat] * mmbtu, 1), fmt.call(r[:elec]), r[:fuel] ? fmt.call(r[:fuel] * mmbtu, 1) : '-',
       fmt.call(ratio.call(r[:heat], r[:elec]), 2), r[:fuel] ? fmt.call(ratio.call(r[:heat], r[:fuel]), 2) : '-', fmt.call(r[:run_hours]), share.call(r[:heat])]
    end
    rows += boiler_rows.map do |r|
      [r[:name], "Boiler:HotWater (#{r[:fuel]})", fmt.call(r[:heat] * mmbtu, 1), '-', r[:fuel_kwh].nil? ? '-' : fmt.call(r[:fuel_kwh] * mmbtu, 1),
       '-', r[:fuel_kwh].nil? ? '-' : fmt.call(ratio.call(r[:heat], r[:fuel_kwh]), 3), '-', share.call(r[:heat])]
    end
    rows << ['Total', '', fmt.call(plant * mmbtu, 1), fmt.call(hp_elec), '', '', '', '', '100%'] if hp_rows.size + boiler_rows.size > 1
    out << table.call(['Equipment', 'Type', 'Heat (MMBtu)', 'Electricity (kWh)', 'Fuel (MMBtu)', 'COP', 'Heat / fuel', 'Hours running', 'Share of plant heat'], rows)
    unless with_t.empty?
      out << "<h2>Heat pump source temperature</h2><p>All hours of the run period. Lockout temperature #{esc.call(fmt.call(lockout_f, 1))} F.</p>"
      out << table.call(['Heat pump', 'Source', 'Min (F)', 'Mean (F)', 'Max (F)', "Hours at or below #{fmt.call(lockout_f, 0)} F"],
                        with_t.map { |r| [r[:name], r[:source], fmt.call(r[:t_min], 1), fmt.call(r[:t_mean], 1), fmt.call(r[:t_max], 1), fmt.call(r[:lockout_hours])] })
    end
    month_names = %w[- Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    head = ['Month']
    hp_rows.each { |r| head << "#{r[:name]} heat (MMBtu)" << "#{r[:name]} COP" }
    boiler_rows.each { |r| head << "#{r[:name]} heat (MMBtu)" }
    mrows = (1..12).map do |m|
      row = [month_names[m]]
      hp_rows.each { |r| row << fmt.call(r[:mq][m] * mmbtu, 1) << fmt.call(ratio.call(r[:mq][m], r[:me][m]), 2) }
      boiler_rows.each { |r| row << fmt.call(r[:mq][m] * mmbtu, 1) }
      row
    end
    out << '<h2>Monthly</h2>' << table.call(head, mrows)

    template = File.read(File.join(File.dirname(__FILE__), 'resources', 'report.html.in'))
    output = out.join("\n")
    File.write('./report.html', ERB.new(template).result(binding))

    runner.registerFinalCondition(format('Heat pumps: %.1f MMBtu heat, %.0f kWh electricity, seasonal COP %s, %s of plant heat. Boilers: %.1f MMBtu heat.',
                                         hp_heat * mmbtu, hp_elec, fmt.call(ratio.call(hp_heat, hp_elec), 2), share.call(hp_heat), b_heat * mmbtu))
    true
    # --- end user logic ---
    return true
  end
end

HeatPumpPlantSummary.new.registerWithApplication
