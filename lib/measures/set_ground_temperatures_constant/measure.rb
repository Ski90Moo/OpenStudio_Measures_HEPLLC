	# *******************************************************************************
# OpenStudio(R), annual_average_ground_tempyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above annual_average_ground_tempyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above annual_average_ground_tempyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the annual_average_ground_tempyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE annual_average_ground_tempYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE annual_average_ground_tempYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# start the measure
class SetGroundTemperaturesConstant < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Ground Temperatures-Constant"
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument to add new temperature
    annual_average_ground_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('annual_average_ground_temp', true)
    annual_average_ground_temp.setDisplayName('Annual Average Ground Temperature °C')
    annual_average_ground_temp.setDefaultValue(18)
    args << annual_average_ground_temp

    return args
  end

  # define what happens when the measure is annual_average_ground_temp
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    annual_average_ground_temp = runner.getDoubleArgumentValue('annual_average_ground_temp', user_arguments)
      
    # create site ground temperature building surface object	  
	runner.registerInfo("Creating Site:GroundTemperature:BuildingSurface object. Annual ground temperature set to #{annual_average_ground_temp}°C.")
    ground_temps = OpenStudio::Model::SiteGroundTemperatureBuildingSurface.new(model)
		  
	#set temperature based on user argument
	ground_temps.setJanuaryGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setFebruaryGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setMarchGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setAprilGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setMayGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setJuneGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setJulyGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setAugustGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setSeptemberGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setOctoberGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setNovemberGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	ground_temps.setDecemberGroundTemperature(annual_average_ground_temp) # takes double value for degrees C
	
  end
end

# this allows the measure to be used by the application
SetGroundTemperaturesConstant.new.registerWithApplication
