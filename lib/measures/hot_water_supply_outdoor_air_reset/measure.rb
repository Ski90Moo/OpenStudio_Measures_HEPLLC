class HotWaterSupplyOutdoorAirReset < OpenStudio::Measure::ModelMeasure
  def name
    return "Hot Water Supply Outdoor Air Reset"
  end

  def description
    return "Replaces the supply temperature control on a hot water loop, for space heating or service water, with an outdoor air reset. The supply water temperature is held at a high value in cold weather, at a low value in mild weather, and varies linearly in between. All four reset points are entered in degrees F."
  end

  def modeler_description
    return "Finds the selected PlantLoop and removes every setpoint manager on its supply outlet node, then adds a SetpointManagerOutdoorAirReset (control variable Temperature) there. Inputs in deg F are converted to deg C. Only the supply outlet node is changed: setpoint managers on component outlet nodes, such as a boiler's own outlet, are left as they are and listed in the output. Sizing:Plant is not changed. The measure warns if the loop is not sized as a Heating loop, or if the reset runs backward (a higher supply temperature in mild weather)."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # Choices are the model's plant loops. Default: the first Heating-sized loop.
    loops = model.getPlantLoops
    loop_names = OpenStudio::StringVector.new
    loops.each { |l| loop_names << l.name.to_s }
    hw_loop_name = OpenStudio::Measure::OSArgument.makeChoiceArgument("hw_loop_name", loop_names, true)
    hw_loop_name.setDisplayName("Hot water plant loop")
    hw_loop_name.setDescription("Hot water PlantLoop (space heating or service water) to receive the outdoor air reset, chosen from the plant loops in the model.")
    default_loop = loops.find { |l| l.sizingPlant.loopType.to_s.casecmp('Heating').zero? }
    hw_loop_name.setDefaultValue(default_loop.name.to_s) if default_loop
    args << hw_loop_name
    sp_at_low_oa_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("sp_at_low_oa_f", true)
    sp_at_low_oa_f.setDisplayName("Supply temperature at low outdoor temperature (F)")
    sp_at_low_oa_f.setDescription("Hot water supply setpoint when the outdoor dry-bulb is at or below the low outdoor temperature, deg F.")
    sp_at_low_oa_f.setDefaultValue(180.0)
    args << sp_at_low_oa_f
    low_oa_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("low_oa_f", true)
    low_oa_f.setDisplayName("Low outdoor temperature (F)")
    low_oa_f.setDescription("Outdoor dry-bulb at and below which the low-OA supply setpoint applies, deg F.")
    low_oa_f.setDefaultValue(0.0)
    args << low_oa_f
    sp_at_high_oa_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("sp_at_high_oa_f", true)
    sp_at_high_oa_f.setDisplayName("Supply temperature at high outdoor temperature (F)")
    sp_at_high_oa_f.setDescription("Hot water supply setpoint when the outdoor dry-bulb is at or above the high outdoor temperature, deg F.")
    sp_at_high_oa_f.setDefaultValue(140.0)
    args << sp_at_high_oa_f
    high_oa_f = OpenStudio::Measure::OSArgument.makeDoubleArgument("high_oa_f", true)
    high_oa_f.setDisplayName("High outdoor temperature (F)")
    high_oa_f.setDescription("Outdoor dry-bulb at and above which the high-OA supply setpoint applies, deg F. Must be greater than the low outdoor temperature.")
    high_oa_f.setDefaultValue(60.0)
    args << high_oa_f
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    hw_loop_name = runner.getStringArgumentValue("hw_loop_name", user_arguments)
    sp_at_low_oa_f = runner.getDoubleArgumentValue("sp_at_low_oa_f", user_arguments)
    low_oa_f = runner.getDoubleArgumentValue("low_oa_f", user_arguments)
    sp_at_high_oa_f = runner.getDoubleArgumentValue("sp_at_high_oa_f", user_arguments)
    high_oa_f = runner.getDoubleArgumentValue("high_oa_f", user_arguments)
    # --- begin user logic ---
    f2c = lambda { |f| (f - 32.0) * 5.0 / 9.0 }
    if high_oa_f <= low_oa_f
      runner.registerError("High outdoor temperature (#{high_oa_f}F) must be greater than low outdoor temperature (#{low_oa_f}F).")
      return false
    end
    if sp_at_high_oa_f > sp_at_low_oa_f
      runner.registerWarning("Supply temperature at high OA (#{sp_at_high_oa_f}F) is above the one at low OA (#{sp_at_low_oa_f}F); the reset runs backward.")
    end

    loop = model.getPlantLoopByName(hw_loop_name)
    if loop.empty?
      runner.registerError("Plant loop '#{hw_loop_name}' not found.")
      return false
    end
    loop = loop.get
    loop_type = loop.sizingPlant.loopType.to_s
    runner.registerWarning("'#{loop.name}' is sized as a '#{loop_type}' loop, not 'Heating'.") unless loop_type.casecmp('Heating').zero?

    outlet = loop.supplyOutletNode
    old = outlet.setpointManagers
    runner.registerInitialCondition("'#{loop.name}' supply outlet setpoint managers: #{old.empty? ? 'none' : old.map { |s| "#{s.name} (#{s.iddObjectType.valueDescription})" }.join(', ')}.")
    old.each do |spm|
      runner.registerInfo("Removing setpoint manager '#{spm.name}' from '#{outlet.name}'.")
      spm.remove
    end

    oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
    oar.setName("#{loop.name} Supply OA Reset")
    oar.setControlVariable('Temperature')
    oar.setSetpointatOutdoorLowTemperature(f2c.call(sp_at_low_oa_f))
    oar.setOutdoorLowTemperature(f2c.call(low_oa_f))
    oar.setSetpointatOutdoorHighTemperature(f2c.call(sp_at_high_oa_f))
    oar.setOutdoorHighTemperature(f2c.call(high_oa_f))
    unless oar.addToNode(outlet)
      runner.registerError("Could not add the outdoor air reset to '#{outlet.name}'.")
      return false
    end

    # Setpoint managers elsewhere on the supply side are kept but reported.
    loop.supplyComponents.each do |c|
      n = c.to_Node
      next if n.empty? || n.get.handle == outlet.handle
      n.get.setpointManagers.each do |s|
        runner.registerInfo("Kept setpoint manager '#{s.name}' on supply node '#{n.get.name}'.")
      end
    end

    runner.registerFinalCondition("'#{loop.name}' supply: #{sp_at_low_oa_f}F at #{low_oa_f}F OA, reset to #{sp_at_high_oa_f}F at #{high_oa_f}F OA.")
    true
    # --- end user logic ---
    return true
  end
end

HotWaterSupplyOutdoorAirReset.new.registerWithApplication
