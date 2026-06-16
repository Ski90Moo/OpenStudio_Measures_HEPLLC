require 'openstudio'

class ApplyShadingPropertiesToAll < OpenStudio::Measure::ModelMeasure
  def name
    'Apply Shading Properties To All Site and Building Shading Surfaces'
  end

  def description
    'Assigns a Construction and/or Transmittance Schedule to every shading surface ' \
    'that belongs to a ShadingSurfaceGroup with Shading Surface Type of Site or Building.'
  end

  def modeler_description
    'Iterates all ShadingSurfaceGroup objects in the model. For groups whose ' \
    'shadingSurfaceType is "Site" or "Building", calls setConstruction and/or ' \
    'setTransmittanceSchedule on each child ShadingSurface. A value of "--- No Change ---" ' \
    'skips that property.'
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # --- Construction choice (optional: first entry = no change) ---
    construction_handles = OpenStudio::StringVector.new
    construction_names   = OpenStudio::StringVector.new
    construction_handles << '0'
    construction_names   << '--- No Change ---'

    construction_hash = {}
    model.getConstructions.each { |c| construction_hash[c.name.to_s] = c }
    construction_hash.sort.each do |key, val|
      construction_handles << val.handle.to_s
      construction_names   << key
    end

    construction_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(
      'construction', construction_handles, construction_names, true
    )
    construction_arg.setDisplayName('Construction to Assign (or "No Change")')
    construction_arg.setDefaultValue('0')
    args << construction_arg

    # --- Transmittance Schedule choice (optional: first entry = no change) ---
    schedule_handles = OpenStudio::StringVector.new
    schedule_names   = OpenStudio::StringVector.new
    schedule_handles << '0'
    schedule_names   << '--- No Change ---'

    schedule_hash = {}
    model.getSchedules.each { |s| schedule_hash[s.name.to_s] = s }
    schedule_hash.sort.each do |key, val|
      schedule_handles << val.handle.to_s
      schedule_names   << key
    end

    schedule_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(
      'schedule', schedule_handles, schedule_names, true
    )
    schedule_arg.setDisplayName('Transmittance Schedule to Assign (or "No Change")')
    schedule_arg.setDefaultValue('0')
    args << schedule_arg

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # --- Resolve construction ---
    construction_handle_str = runner.getStringArgumentValue('construction', user_arguments)
    apply_construction = (construction_handle_str != '0')
    construction = nil

    if apply_construction
      construction_obj = runner.getOptionalWorkspaceObjectChoiceValue('construction', user_arguments, model)
      if construction_obj.empty? || construction_obj.get.to_Construction.empty?
        runner.registerError("Selected construction was not found in the model.")
        return false
      end
      construction = construction_obj.get.to_Construction.get
    end

    # --- Resolve schedule ---
    schedule_handle_str = runner.getStringArgumentValue('schedule', user_arguments)
    apply_schedule = (schedule_handle_str != '0')
    schedule = nil

    if apply_schedule
      schedule_obj = runner.getOptionalWorkspaceObjectChoiceValue('schedule', user_arguments, model)
      if schedule_obj.empty? || schedule_obj.get.to_Schedule.empty?
        runner.registerError("Selected schedule was not found in the model.")
        return false
      end
      schedule = schedule_obj.get.to_Schedule.get
    end

    unless apply_construction || apply_schedule
      runner.registerAsNotApplicable('No construction or schedule selected — nothing to change.')
      return true
    end

    # --- Initial condition ---
    all_groups = model.getShadingSurfaceGroups
    target_groups = all_groups.select { |g| %w[Site Building].include?(g.shadingSurfaceType) }
    runner.registerInitialCondition(
      "Model contains #{all_groups.size} shading surface group(s); " \
      "#{target_groups.size} have type Site or Building."
    )

    if target_groups.empty?
      runner.registerAsNotApplicable('No Site or Building shading surface groups found — nothing to change.')
      return true
    end

    # --- Apply properties ---
    groups_modified   = 0
    surfaces_modified = 0

    target_groups.each do |group|
      surfaces = group.shadingSurfaces
      next if surfaces.empty?

      groups_modified += 1
      surfaces.each do |surface|
        surface.setConstruction(construction)         if apply_construction
        surface.setTransmittanceSchedule(schedule)    if apply_schedule
        surfaces_modified += 1
      end
    end

    # --- Final condition ---
    applied = []
    applied << "construction '#{construction.name}'" if apply_construction
    applied << "transmittance schedule '#{schedule.name}'" if apply_schedule

    runner.registerFinalCondition(
      "Applied #{applied.join(' and ')} to #{surfaces_modified} shading surface(s) " \
      "across #{groups_modified} Site/Building group(s)."
    )

    true
  end
end

ApplyShadingPropertiesToAll.new.registerWithApplication
