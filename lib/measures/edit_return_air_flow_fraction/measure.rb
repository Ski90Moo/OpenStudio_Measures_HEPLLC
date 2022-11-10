# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class EditReturnAirFlowFraction < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "Edit Return Air Flow Fraction"
  end
  # human readable description
  def description
    return "This modifies the Design Return Air Flow Fraction of Supply Air Flow from the default of 1 for cases where the system return fan never returns as much airflow as the supply fan."
  end
  # human readable description of modeling approach
  def modeler_description
    return "This measure is puts a maximum on the return fan airflow. If the fan is set for autosized, it does not affect the sizing of the return fan. It will only limit the return fan flow rate during the simulation."
  end
  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the AirLoop to be edited
    loop_name = OpenStudio::Measure::OSArgument.makeStringArgument('loop_name', true)
    loop_name.setDisplayName('Air Loop with Return Fan')
    args << loop_name

    # design return airflow fraction of supply air ratio
    return_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('return_fraction', true)
    return_fraction.setDisplayName('Return Air Flow Fraction')
    return_fraction.setUnits('Fraction')
    args << return_fraction

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    loop_name = runner.getStringArgumentValue('loop_name', user_arguments)
    return_fraction = runner.getDoubleArgumentValue('return_fraction', user_arguments)

    # get all hvac air loops in the model
    air_loops = workspace.getObjectsByType('AirLoopHVAC'.to_IddObjectType)
    # reporting initial condition of model
	runner.registerInitialCondition("The building started with #{air_loops.size} AirLoopHVAC objects.")

    # validate input names
    loop_name_valid = false
    air_loops.each do |air_loop|
      if loop_name == air_loop.getString(0).to_s
        loop_name_valid = true
      end
    end

    # error if didn't find loop name
     if (loop_name_valid == false)
       runner.registerError('The expected air loop could not be found..')
       return false
     end

    # validate design level input
     if (return_fraction < 0.0) || (return_fraction > 1.0)
       runner.registerError('Choose a number between 0 and 1 for return air flow fraction.')
       return false
     end
	 
	 runner.registerInfo("requested return flow fraction: #{return_fraction}")

    air_loops.each do |air_loop|
		if loop_name == air_loop.getString(0).to_s
			num_of_fields = air_loop.numFields #Count Initial number of fields in Object
			runner.registerInfo("There are #{num_of_fields} fields in this air loop")
			air_loop.setString(10, return_fraction.to_s) #Overwrite return air flow fraction
			num_of_fields = air_loop.numFields #Count Final number of fields in Object
			runner.registerInfo("There are now #{num_of_fields} fields in this air loop")
			runner.registerFinalCondition("Return air flow fraction of supply air flow was changed to #{return_fraction}.")
		end
	end

    return true
  end
end

# register the measure to be used by the application
EditReturnAirFlowFraction.new.registerWithApplication
