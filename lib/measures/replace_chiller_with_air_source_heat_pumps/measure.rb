# start the measure
class ReplaceChillerWithAirSourceHeatPumps < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Replace Chiller with Air Source Heat Pumps'
  end

  # human readable description
  def description
    return 'This measure removes the condenser water loop and cooling tower, replaces the water-cooled chiller with an air-source heat pump for cooling, and adds an air-source heat pump for heating in parallel with the existing boiler.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure deletes the condenser water plant loop with CoolingTower:SingleSpeed. It replaces the Chiller:Electric:EIR with a HeatPump:PlantLoop:EIR:Cooling object. It also adds a HeatPump:PlantLoop:EIR:Heating object in parallel to the existing Boiler:HotWater on the heating water loop.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Cooling heat pump capacity (optional - can be autosized)
    cooling_hp_capacity = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_hp_capacity', false)
    cooling_hp_capacity.setDisplayName('Cooling Heat Pump Capacity (W)')
    cooling_hp_capacity.setDescription('Reference capacity of the cooling heat pump. Leave blank for autosize.')
    args << cooling_hp_capacity

    # Heating heat pump capacity (optional - can be autosized)
    heating_hp_capacity = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_hp_capacity', false)
    heating_hp_capacity.setDisplayName('Heating Heat Pump Capacity (W)')
    heating_hp_capacity.setDescription('Reference capacity of the heating heat pump. Leave blank for autosize.')
    args << heating_hp_capacity

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    cooling_hp_capacity = runner.getOptionalDoubleArgumentValue('cooling_hp_capacity', user_arguments)
    heating_hp_capacity = runner.getOptionalDoubleArgumentValue('heating_hp_capacity', user_arguments)

    # TASK 1: Find and delete the condenser water loop
    condenser_loop_deleted = false
    model.getPlantLoops.each do |plant_loop|
      # Check if this is a condenser water loop by looking for cooling towers
      plant_loop.supplyComponents.each do |component|
        if component.to_CoolingTowerSingleSpeed.is_initialized
          runner.registerInfo("Found condenser water loop: #{plant_loop.name}")
          plant_loop.remove
          condenser_loop_deleted = true
          runner.registerInfo("Deleted condenser water loop with cooling tower")
          break
        end
      end
      break if condenser_loop_deleted
    end

    if !condenser_loop_deleted
      runner.registerWarning('No condenser water loop with CoolingTower:SingleSpeed was found')
    end

    # TASK 2: Find and replace the water-cooled chiller with air-source cooling heat pump
    chiller_loop = nil
    chiller_replaced = false
    
    model.getPlantLoops.each do |plant_loop|
      plant_loop.supplyComponents.each do |component|
        if component.to_ChillerElectricEIR.is_initialized
          chiller = component.to_ChillerElectricEIR.get
          chiller_loop = plant_loop
          runner.registerInfo("Found chiller: #{chiller.name} on loop: #{plant_loop.name}")
          
          # Get the chiller's capacity for reference
          if chiller.referenceCapacity.is_initialized
            ref_capacity = chiller.referenceCapacity.get
            runner.registerInfo("Chiller reference capacity: #{ref_capacity} W")
          end
          
          # Create the air-source cooling heat pump
          cooling_hp = OpenStudio::Model::HeatPumpPlantLoopEIRCooling.new(model)
          cooling_hp.setName('Air Source Heat Pump - Cooling')
          
          # Set capacity if provided by user, otherwise autosize
          if cooling_hp_capacity.is_initialized
            cooling_hp.setReferenceCapacity(cooling_hp_capacity.get)
            runner.registerInfo("Set cooling heat pump capacity to #{cooling_hp_capacity.get} W")
          else
            cooling_hp.autosizeReferenceCapacity
            runner.registerInfo('Cooling heat pump capacity set to autosize')
          end
          
          # Set reasonable default performance values
          cooling_hp.setReferenceCoefficientofPerformance(3.5)
          cooling_hp.setSizingFactor(1.0)
          cooling_hp.setCondenserType('AirCooled')
          
          # Set flow rates to autosize
          cooling_hp.autosizeLoadSideReferenceFlowRate
          cooling_hp.autosizeSourceSideReferenceFlowRate
          
          # Add the cooling heat pump to the chilled water loop
          cooling_hp.addToNode(plant_loop.supplyInletNode)
          
          # Remove the old chiller
          chiller.remove
          
          chiller_replaced = true
          runner.registerInfo('Replaced water-cooled chiller with air-source cooling heat pump')
          break
        end
      end
      break if chiller_replaced
    end

    if !chiller_replaced
      runner.registerError('No Chiller:Electric:EIR was found to replace')
      return false
    end

    # TASK 3: Add air-source heating heat pump in parallel with boiler
    heating_hp_added = false
    
    model.getPlantLoops.each do |plant_loop|
      plant_loop.supplyComponents.each do |component|
        if component.to_BoilerHotWater.is_initialized
          boiler = component.to_BoilerHotWater.get
          runner.registerInfo("Found boiler: #{boiler.name} on loop: #{plant_loop.name}")
          
          # Create the air-source heating heat pump
          heating_hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
          heating_hp.setName('Air Source Heat Pump - Heating')
          
          # Set capacity if provided by user, otherwise autosize
          if heating_hp_capacity.is_initialized
            heating_hp.setReferenceCapacity(heating_hp_capacity.get)
            runner.registerInfo("Set heating heat pump capacity to #{heating_hp_capacity.get} W")
          else
            heating_hp.autosizeReferenceCapacity
            runner.registerInfo('Heating heat pump capacity set to autosize')
          end
          
          # Set reasonable default performance values
          heating_hp.setReferenceCoefficientofPerformance(3.0)
          heating_hp.setSizingFactor(1.0)
          heating_hp.setCondenserType('AirCooled')
          
          # Set flow rates to autosize
          heating_hp.autosizeLoadSideReferenceFlowRate
          heating_hp.autosizeSourceSideReferenceFlowRate
          
          # Add the heating heat pump to the hot water loop (in parallel with boiler)
          heating_hp.addToNode(plant_loop.supplyInletNode)
          
          heating_hp_added = true
          runner.registerInfo('Added air-source heating heat pump in parallel with boiler')
          break
        end
      end
      break if heating_hp_added
    end

    if !heating_hp_added
      runner.registerWarning('No Boiler:HotWater was found. Heating heat pump was not added.')
    end

    # Report final condition
    runner.registerFinalCondition("Successfully modified HVAC system: condenser loop deleted=#{condenser_loop_deleted}, chiller replaced=#{chiller_replaced}, heating HP added=#{heating_hp_added}")

    return true
  end
end

# register the measure to be used by the application
ReplaceChillerWithAirSourceHeatPumps.new.registerWithApplication
