require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class CreateAirToWaterHeatPumpTest < Minitest::Test
  F2C = lambda { |f| (f - 32.0) / 1.8 }

  def run_measure(model, args_hash = {})
    measure = CreateAirToWaterHeatPump.new
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

  def coeffs(curve)
    c = curve.to_CurveBiquadratic.get
    [c.coefficient1Constant, c.coefficient2x, c.coefficient3xPOW2, c.coefficient4y, c.coefficient5yPOW2, c.coefficient6xTIMESY]
  end

  def bq(co, x, y)
    [1.0, x, x * x, y, y * y, x * y].zip(co).sum { |a, b| a * b }
  end

  def test_number_of_arguments
    assert_equal(20, CreateAirToWaterHeatPump.new.arguments(OpenStudio::Model::Model.new).size)
  end

  def test_defaults_create_unconnected_heat_pump
    model = OpenStudio::Model::Model.new
    result = run_measure(model)
    assert_equal('Success', result.value.valueName)

    hp = model.getHeatPumpPlantLoopEIRHeatingByName('Air-to-Water Heat Pump').get
    assert(hp.plantLoop.empty?)
    assert_equal('AirSource', hp.condenserType)
    assert_equal('Timed', hp.heatPumpDefrostControl)
    assert_in_delta(937.6 * 1000.0 / 3.412142, hp.referenceCapacity.get, 1e-6)
    assert_in_delta(2.191, hp.referenceCoefficientofPerformance, 1e-9)

    # Both curves are 1.0 at 19F OA / 113F leaving water.
    cap = coeffs(hp.capacityModifierFunctionofTemperatureCurve)
    eir = coeffs(hp.electricInputtoOutputRatioModifierFunctionofTemperatureCurve)
    assert_in_delta(1.0, bq(cap, F2C.call(113.0), F2C.call(19.0)), 1e-9)
    assert_in_delta(1.0, bq(eir, F2C.call(113.0), F2C.call(19.0)), 1e-9)

    # Linear CapFT: +1.17 %/F OA, -0.3 %/F leaving water.
    [1.39510000e+00, -5.40000000e-03, 0.0, 2.10600000e-02, 0.0, 0.0].zip(cap).each { |e, a| assert_in_delta(e, a, 1e-9) }
    # Carnot EIRFT fit, independently computed with numpy lstsq.
    [1.84138301e-01, 1.74066372e-02, -4.22193861e-05, -1.86384016e-02, 0.0, 5.09335298e-05].zip(eir).each { |e, a| assert_in_delta(e, a, 1e-9) }

    # Unused default curves are removed: only the two named curves remain.
    assert_equal(2, model.getCurveBiquadratics.size)
  end

  def test_overrides_used_as_entered
    model = OpenStudio::Model::Model.new
    co = '1.85527906e-01,1.73553635e-02,-4.17479305e-05,-1.86161641e-02,0,5.05531595e-05'
    result = run_measure(model, 'hp_name' => 'HP', 'eirft_override' => co, 'defrost_control' => 'None')
    assert_equal('Success', result.value.valueName)
    hp = model.getHeatPumpPlantLoopEIRHeatingByName('HP').get
    co.split(',').map(&:to_f).zip(coeffs(hp.electricInputtoOutputRatioModifierFunctionofTemperatureCurve)).each { |e, a| assert_in_delta(e, a, 1e-12) }
    assert_equal('None', hp.heatPumpDefrostControl)
  end

  def test_bad_override_fails
    result = run_measure(OpenStudio::Model::Model.new, 'capft_override' => '1,2,3')
    assert_equal('Fail', result.value.valueName)
  end

  def test_duplicate_name_fails
    model = OpenStudio::Model::Model.new
    assert_equal('Success', run_measure(model).value.valueName)
    assert_equal('Fail', run_measure(model).value.valueName)
    assert_equal(1, model.getHeatPumpPlantLoopEIRHeatings.size)
  end

  def test_rating_point_outside_limits_fails
    result = run_measure(OpenStudio::Model::Model.new, 'rated_oat_f' => 80.0)
    assert_equal('Fail', result.value.valueName)
  end
end
