class SetOutputEnvironmentalImpactFactors < OpenStudio::Measure::ModelMeasure

  # define the name that a user will see
  def name
    return "Set OutputEnvironmentalImpactFactors"
  end
  # human readable description
  def description
    return "This measure initializes the Output:EnvironmentalImpactFactors, EnvironmentalImpactFactors, and FuelFactors objects.  It also allows the user to change district heating efficiency."
  end
  # human readable description of modeling approach
  def modeler_description
    return "This measure initializes the Output:EnvironmentalImpactFactors, EnvironmentalImpactFactors, and FuelFactors objects.  It also allows the user to change district heating efficiency."
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
	
	# make an argument for district heating efficiency
    dist_heat_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument('dist_heat_eff', true)
    dist_heat_eff.setDisplayName('District Heating Efficiency')
    dist_heat_eff.setDescription('Energy conversion efficiency of District Heating')
    dist_heat_eff.setDefaultValue(0.3)
    args << dist_heat_eff
	
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

	# assign the user inputs to variables
    dist_heat_eff = runner.getDoubleArgumentValue('dist_heat_eff', user_arguments)


	# report initial condition of model
	fuel_factors = OpenStudio::Model::FuelFactors.new(model)
	envimp_factors = OpenStudio::Model::OutputEnvironmentalImpactFactors.new(model)
	env_impct_obj = model.getEnvironmentalImpactFactors
    default_district_heat_eff = env_impct_obj.districtHeatingEfficiency
    runner.registerInitialCondition("The initial district heating efficiency is #{default_district_heat_eff}")

    # change district heating efficiency
	env_impct_obj.setDistrictHeatingEfficiency(dist_heat_eff)
	runner.registerFinalCondition("Changed District Heating efficiency to #{dist_heat_eff}.")
      
    return true
  end

end

SetOutputEnvironmentalImpactFactors.new.registerWithApplication
