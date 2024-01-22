class SetOutputTableToIPUnitsV2 < OpenStudio::Ruleset::OpenStudio::Measure::EnergyPlusMeasure

  def name
    return "Set Output Table To IP Units v2"
  end

  # human readable description
  def description
    return "This measure changes the output table to be in IP units but the sql file remains in SI units to allow generation of OpenStudio Results. Report is outputted in HTML and tab delimited. Includes output for Sizing period (ie. zone level reports). Only compatible with EnergyPlus versions after Feb 18, 2021"
  end

  # human readable description of modeling approach
  def modeler_description
    return "This EnergyPlus measure sets the OutputControl:Table:Style to InchPound and TabAndHTML. Sets 'Unit Conversion for Tabular Data' in Output:SQLite to 'None'. Sets 'Report 1' to AllSummaryAndSizingPeriod."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # if IP units requested add OutputControl:Table:Style object
    table_style = workspace.getObjectsByType("OutputControl:Table:Style".to_IddObjectType)

    # even though there is just a single object, it is still in an array
    if not table_style.empty?
      # we can access the first object in the array using the table_style[0]
      # use setString to change the field value to request IP units
	  table_style_w_tab = table_style[0].setString(0,"TabAndHTML")
      table_style_ip = table_style[0].setString(1,"InchPound")
    end
	
	# set 'Unit Conversion for Tabular Data' in Output:SQLite to 'None'
    os = workspace.getObjectsByType('Output:SQLite'.to_IddObjectType)
	os.each{|o| o.setString(1,"None")}
		
	#Set 'All Summary and Sizing Period' in Output:Table:SummaryReports
	osr = workspace.getObjectsByType('Output:Table:SummaryReports'.to_IddObjectType)
	osr.each{|o| o.setString(0,"AllSummaryAndSizingPeriod")}
	
    return true
  end
end

# this allows the measure to be use by the application
SetOutputTableToIPUnitsV2.new.registerWithApplication
