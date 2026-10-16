require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class CreateWaterToWaterHeatPumpTest < Minitest::Test
  F2C = lambda { |f| (f - 32.0) / 1.8 }

  def run_measure(model, args_hash = {})
    measure = CreateWaterToWaterHeatPump.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    arguments.each do |arg|
      temp_arg_var = arg.clone
      assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash.key?(arg.name)
      argument_map[arg.name] = temp_arg_var
    end
    measure.run(model, runner, argument_map)
    result = runner.result
    result.showOutput
    result
  end

  def test_defaults
    model = OpenStudio::Model::Model.new
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)
    # Default curves are normalized at the default rating point.
    assert_equal(0, result.warnings.size)
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('Water-to-Water Heat Pump').get
    assert(hp.plantLoop.empty?)
    assert(hp.secondaryPlantLoop.empty?)
    # Unconnected: OpenStudio reports air source; the intent is tagged.
    assert_equal('AirSource', hp.condenserType)
    assert_equal('WaterSource', hp.additionalProperties.getFeatureAsString('IntendedCondenserType').get)
    assert_equal('Setpoint', hp.controlType)
    assert_in_delta(617.8 * 1000.0 / 3.412142, hp.referenceCapacity.get, 1e-6)
    assert_in_delta(3.575, hp.referenceCoefficientofPerformance, 1e-9)
    assert_in_delta(100.0 * 6.30902e-5, hp.loadSideReferenceFlowRate.get, 1e-12)
    assert_in_delta(200.0 * 6.30902e-5, hp.sourceSideReferenceFlowRate.get, 1e-12)
    assert_in_delta(F2C.call(25.0), hp.minimumSourceInletTemperature, 1e-9)
    cap = hp.capacityModifierFunctionofTemperatureCurve.to_CurveBiquadratic.get
    assert_equal('Water-to-Water Heat Pump CapFT', cap.name.to_s)
    assert_in_delta(1.11556398, cap.coefficient1Constant, 1e-9)
    assert_in_delta(20.0, cap.minimumValueofx, 1e-9)
    assert_in_delta(33.0, cap.maximumValueofy, 1e-9)
    eir = hp.electricInputtoOutputRatioModifierFunctionofTemperatureCurve.to_CurveBiquadratic.get
    assert_in_delta(-3.94876566e-04, eir.coefficient6xTIMESY, 1e-15)
    # The scaffold's default temperature curves are removed.
    assert_equal(2, model.getCurveBiquadratics.size)
  end

  def test_rating_point_off_curve_warns
    model = OpenStudio::Model::Model.new
    result = run_measure(model, 'rated_est_f' => 70.0)
    assert_equal('Success', result.value.valueName)
    assert_equal(2, result.warnings.size)
  end

  def test_bad_coefficients_fail
    model = OpenStudio::Model::Model.new
    assert_equal('Fail', run_measure(model, 'eirft_coeffs' => '1,2,3').value.valueName)
    assert(model.getHeatPumpPlantLoopEIRHeatings.empty?)
  end

  def test_duplicate_name_fails
    model = OpenStudio::Model::Model.new
    assert_equal('Success', run_measure(model).value.valueName)
    assert_equal('Fail', run_measure(model).value.valueName)
    assert_equal(1, model.getHeatPumpPlantLoopEIRHeatings.size)
  end

  def test_rating_point_outside_limits_fails
    model = OpenStudio::Model::Model.new
    assert_equal('Fail', run_measure(model, 'rated_est_f' => 100.0).value.valueName)
  end
  def test_maximum_supply_water_temperature
    model = OpenStudio::Model::Model.new
    assert_equal('Success', run_measure(model).value.valueName)
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('Water-to-Water Heat Pump').get
    assert_in_delta(0.5, hp.minimumPartLoadRatio, 1e-12)
    table = hp.maximumSupplyWaterTemperatureCurve.get.to_TableLookup.get
    assert_equal('Water-to-Water Heat Pump Maximum Supply Water Temperature', table.name.to_s)
    iv = table.independentVariables[0]
    [30.0, 50.0, 70.0, 90.0].zip(iv.values.to_a).each { |e, a| assert_in_delta(F2C.call(e), a, 1e-9) }
    [129.4, 132.3, 135.2, 118.8].zip(table.outputValues.to_a).each { |e, a| assert_in_delta(F2C.call(e), a, 1e-9) }

    # Above the curves' leaving water limit: warned.
    result = run_measure(OpenStudio::Model::Model.new, 'max_supply_points' => '30:130, 70:150')
    assert_equal('Success', result.value.valueName)
    assert(result.warnings.any? { |w| w.logMessage.include?("above the curves' maximum") })

    # Below the rated leaving load water temperature (112.4F) at the rating EST: fails.
    assert_equal('Fail', run_measure(OpenStudio::Model::Model.new, 'max_supply_points' => '30:105, 70:110').value.valueName)
    assert_equal('Fail', run_measure(OpenStudio::Model::Model.new, 'max_supply_points' => 'abc').value.valueName)
  end
end
