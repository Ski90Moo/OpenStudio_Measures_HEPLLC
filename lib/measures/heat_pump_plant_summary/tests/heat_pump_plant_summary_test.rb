require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class HeatPumpPlantSummaryTest < Minitest::Test
  # Hot water loop with a propane boiler and the given heating component on a supply branch.
  def plant_model
    model = OpenStudio::Model::Model.new
    loop = OpenStudio::Model::PlantLoop.new(model)
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setFuelType('Propane')
    loop.addSupplyBranchForComponent(boiler)
    [model, loop]
  end

  def requests(model)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model) if model
    measure = HeatPumpPlantSummary.new
    args = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments)
    measure.energyPlusOutputRequests(runner, args).map { |o| o.getString(1).get }
  end

  def test_arguments
    args = HeatPumpPlantSummary.new.arguments
    assert_equal(['lockout_f'], args.map(&:name))
    assert_equal(25.0, args[0].defaultValueAsDouble)
  end

  def test_requests_for_eir_heat_pump_and_boiler
    model, loop = plant_model
    hp = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
    loop.addSupplyBranchForComponent(hp)
    # Not on a loop: ignored.
    OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
    names = requests(model)
    assert_equal(['Heat Pump Load Side Heat Transfer Rate', 'Heat Pump Electricity Rate', 'Heat Pump Source Side Inlet Temperature',
                  'Boiler Heating Rate', 'Boiler Propane Rate'].sort, names.sort)
  end

  def test_requests_for_air_to_water_and_fuel_fired
    model, loop = plant_model
    awhp = OpenStudio::Model::HeatPumpAirToWater.new(model)
    heating = OpenStudio::Model::HeatPumpAirToWaterHeating.new(model)
    awhp.setHeatingOperationMode(heating)
    loop.addSupplyBranchForComponent(heating)
    loop.addSupplyBranchForComponent(OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model))
    names = requests(model)
    assert_includes(names, 'Heat Pump Load Side Heat Transfer Rate in Heating Mode')
    assert_includes(names, 'Fuel-fired Absorption HeatPump Fuel Rate')
    assert_includes(names, 'Site Outdoor Air Drybulb Temperature')
    refute_includes(names, 'Heat Pump Load Side Heat Transfer Rate')
  end

  def test_requests_without_model
    names = requests(nil)
    assert_includes(names, 'Heat Pump Load Side Heat Transfer Rate')
    assert_includes(names, 'Fuel-fired Absorption HeatPump Load Side Heat Transfer Rate')
    assert_includes(names, 'Boiler Heating Rate')
  end
end
