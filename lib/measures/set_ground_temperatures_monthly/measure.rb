# *******************************************************************************
# OpenStudio(R), janyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above janyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above janyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the janyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE janYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE janYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# start the measure
class SetGroundTemperaturesMonthly < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Ground Temperatures-Monthly"
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument to add new temperature
    jan = OpenStudio::Measure::OSArgument.makeDoubleArgument('jan', true)
    jan.setDisplayName('January Average Ground Temperature °C')
    jan.setDefaultValue(17)
    args << jan

    # make an argument to add new temperature
    feb = OpenStudio::Measure::OSArgument.makeDoubleArgument('feb', true)
    feb.setDisplayName('February Average Ground Temperature °C')
    feb.setDefaultValue(17)
    args << feb

    # make an argument to add new temperature
    mar = OpenStudio::Measure::OSArgument.makeDoubleArgument('mar', true)
    mar.setDisplayName('March Average Ground Temperature °C')
    mar.setDefaultValue(17)
    args << mar
	
    # make an argument to add new temperature
    apr = OpenStudio::Measure::OSArgument.makeDoubleArgument('apr', true)
    apr.setDisplayName('April Average Ground Temperature °C')
    apr.setDefaultValue(18)
    args << apr	

    # make an argument to add new temperature
    may = OpenStudio::Measure::OSArgument.makeDoubleArgument('may', true)
    may.setDisplayName('May Average Ground Temperature °C')
    may.setDefaultValue(18)
    args << may	

    # make an argument to add new temperature
    jun = OpenStudio::Measure::OSArgument.makeDoubleArgument('jun', true)
    jun.setDisplayName('June Average Ground Temperature °C')
    jun.setDefaultValue(18)
    args << jun	

    # make an argument to add new temperature
    jul = OpenStudio::Measure::OSArgument.makeDoubleArgument('jul', true)
    jul.setDisplayName('July Average Ground Temperature °C')
    jul.setDefaultValue(19)
    args << jul	

    # make an argument to add new temperature
    aug = OpenStudio::Measure::OSArgument.makeDoubleArgument('aug', true)
    aug.setDisplayName('August Average Ground Temperature °C')
    aug.setDefaultValue(19)
    args << aug

    # make an argument to add new temperature
    sep = OpenStudio::Measure::OSArgument.makeDoubleArgument('sep', true)
    sep.setDisplayName('September Average Ground Temperature °C')
    sep.setDefaultValue(19)
    args << sep

    # make an argument to add new temperature
    oct = OpenStudio::Measure::OSArgument.makeDoubleArgument('oct', true)
    oct.setDisplayName('October Average Ground Temperature °C')
    oct.setDefaultValue(18)
    args << oct

    # make an argument to add new temperature
    nov = OpenStudio::Measure::OSArgument.makeDoubleArgument('nov', true)
    nov.setDisplayName('November Average Ground Temperature °C')
    nov.setDefaultValue(18)
    args << nov

    # make an argument to add new temperature
    dec = OpenStudio::Measure::OSArgument.makeDoubleArgument('dec', true)
    dec.setDisplayName('December Average Ground Temperature °C')
    dec.setDefaultValue(17)
    args << dec

    return args
  end

  # define what happens when the measure is jan
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    jan = runner.getDoubleArgumentValue('jan', user_arguments)
    feb = runner.getDoubleArgumentValue('feb', user_arguments)
    mar = runner.getDoubleArgumentValue('mar', user_arguments)
    apr = runner.getDoubleArgumentValue('apr', user_arguments)
    may = runner.getDoubleArgumentValue('may', user_arguments)
    jun = runner.getDoubleArgumentValue('jun', user_arguments)
    jul = runner.getDoubleArgumentValue('jul', user_arguments)
    aug = runner.getDoubleArgumentValue('aug', user_arguments)
    sep = runner.getDoubleArgumentValue('sep', user_arguments)
    oct = runner.getDoubleArgumentValue('oct', user_arguments)
    nov = runner.getDoubleArgumentValue('nov', user_arguments)	
    dec = runner.getDoubleArgumentValue('dec', user_arguments)	

    # create site ground temperature building surface object	  
	runner.registerInfo("Creating Site:GroundTemperature:BuildingSurface object.")
    runner.registerInfo("January ground temperature set to #{jan}°C.")
	runner.registerInfo("February ground temperature set to #{feb}°C.")
	runner.registerInfo("March ground temperature set to #{mar}°C.")
	runner.registerInfo("April ground temperature set to #{apr}°C.")
	runner.registerInfo("May ground temperature set to #{may}°C.")
	runner.registerInfo("June ground temperature set to #{jun}°C.")
	runner.registerInfo("July ground temperature set to #{jul}°C.")
	runner.registerInfo("August ground temperature set to #{aug}°C.")
	runner.registerInfo("September ground temperature set to #{sep}°C.")
	runner.registerInfo("October ground temperature set to #{oct}°C.")
	runner.registerInfo("November ground temperature set to #{nov}°C.")
	runner.registerInfo("December ground temperature set to #{dec}°C.")
	ground_temps = OpenStudio::Model::SiteGroundTemperatureBuildingSurface.new(model)
		  
	#set each month's temperature manually
	ground_temps.setJanuaryGroundTemperature(jan) # takes double value for degrees C
	ground_temps.setFebruaryGroundTemperature(feb) # takes double value for degrees C
	ground_temps.setMarchGroundTemperature(mar) # takes double value for degrees C
	ground_temps.setAprilGroundTemperature(apr) # takes double value for degrees C
	ground_temps.setMayGroundTemperature(may) # takes double value for degrees C
	ground_temps.setJuneGroundTemperature(jun) # takes double value for degrees C
	ground_temps.setJulyGroundTemperature(jul) # takes double value for degrees C
	ground_temps.setAugustGroundTemperature(aug) # takes double value for degrees C
	ground_temps.setSeptemberGroundTemperature(sep) # takes double value for degrees C
	ground_temps.setOctoberGroundTemperature(oct) # takes double value for degrees C
	ground_temps.setNovemberGroundTemperature(nov) # takes double value for degrees C
	ground_temps.setDecemberGroundTemperature(dec) # takes double value for degrees C
	
  end
end

# this allows the measure to be used by the application
SetGroundTemperaturesMonthly.new.registerWithApplication
