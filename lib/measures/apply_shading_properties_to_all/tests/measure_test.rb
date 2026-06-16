require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class ApplyShadingPropertiesToAllTest < Minitest::Test
  def setup
    @measure = ApplyShadingPropertiesToAll.new
  end

  def make_test_model
    model = OpenStudio::Model::Model.new

    mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    mat.setName('TestMaterial')
    const = OpenStudio::Model::Construction.new(model)
    const.setName('TestConstruction')
    const.insertLayer(0, mat)

    sched = OpenStudio::Model::ScheduleConstant.new(model)
    sched.setName('AlwaysOne')
    sched.setValue(1.0)

    # Site shading surface group
    site_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    site_group.setShadingSurfaceType('Site')
    site_surf = OpenStudio::Model::ShadingSurface.new(
      OpenStudio::Point3dVector.new([
        OpenStudio::Point3d.new(0, 0, 3), OpenStudio::Point3d.new(1, 0, 3),
        OpenStudio::Point3d.new(1, 1, 3), OpenStudio::Point3d.new(0, 1, 3)
      ]), model
    )
    site_surf.setShadingSurfaceGroup(site_group)

    # Building shading surface group
    bldg_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    bldg_group.setShadingSurfaceType('Building')
    bldg_surf = OpenStudio::Model::ShadingSurface.new(
      OpenStudio::Point3dVector.new([
        OpenStudio::Point3d.new(0, 0, 5), OpenStudio::Point3d.new(1, 0, 5),
        OpenStudio::Point3d.new(1, 1, 5), OpenStudio::Point3d.new(0, 1, 5)
      ]), model
    )
    bldg_surf.setShadingSurfaceGroup(bldg_group)

    # Space shading surface group — must NOT be modified
    space = OpenStudio::Model::Space.new(model)
    space_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    space_group.setShadingSurfaceType('Space')
    space_group.setSpace(space)
    space_surf = OpenStudio::Model::ShadingSurface.new(
      OpenStudio::Point3dVector.new([
        OpenStudio::Point3d.new(0, 0, 2), OpenStudio::Point3d.new(1, 0, 2),
        OpenStudio::Point3d.new(1, 1, 2), OpenStudio::Point3d.new(0, 1, 2)
      ]), model
    )
    space_surf.setShadingSurfaceGroup(space_group)

    [model, const, sched, site_surf, bldg_surf, space_surf]
  end

  def set_arg(arg_map, args, name, display_name_value)
    arg = args.find { |a| a.name == name }.clone
    assert arg.setValue(display_name_value), "setValue failed for '#{name}' with value '#{display_name_value}'"
    arg_map[name] = arg
  end

  def test_applies_construction_and_schedule
    model, const, sched, site_surf, bldg_surf, space_surf = make_test_model

    runner  = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args    = @measure.arguments(model)
    arg_map = OpenStudio::Measure.convertOSArgumentVectorToMap(args)

    set_arg(arg_map, args, 'construction', const.name.to_s)
    set_arg(arg_map, args, 'schedule',     sched.name.to_s)

    @measure.run(model, runner, arg_map)
    result = runner.result
    show_output(result)
    assert_equal 'Success', result.value.valueName

    assert !site_surf.construction.empty?,       'Site surface: missing construction'
    assert_equal const.name.to_s,  site_surf.construction.get.name.to_s
    assert !site_surf.transmittanceSchedule.empty?, 'Site surface: missing schedule'
    assert_equal sched.name.to_s,  site_surf.transmittanceSchedule.get.name.to_s

    assert !bldg_surf.construction.empty?,       'Building surface: missing construction'
    assert_equal const.name.to_s,  bldg_surf.construction.get.name.to_s
    assert !bldg_surf.transmittanceSchedule.empty?, 'Building surface: missing schedule'
    assert_equal sched.name.to_s,  bldg_surf.transmittanceSchedule.get.name.to_s

    assert space_surf.construction.empty?,       'Space surface should not be changed'
    assert space_surf.transmittanceSchedule.empty?, 'Space surface should not be changed'
  end

  def test_no_change_skips_both
    model, _const, _sched, site_surf, _bldg, _space = make_test_model

    runner  = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args    = @measure.arguments(model)
    arg_map = OpenStudio::Measure.convertOSArgumentVectorToMap(args)
    # Leave both arguments at their default '--- No Change ---'

    @measure.run(model, runner, arg_map)
    result = runner.result
    show_output(result)
    assert_equal 'NA', result.value.valueName
    assert site_surf.construction.empty?
  end

  def test_schedule_only
    model, _const, sched, site_surf, bldg_surf, _space = make_test_model

    runner  = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    args    = @measure.arguments(model)
    arg_map = OpenStudio::Measure.convertOSArgumentVectorToMap(args)

    set_arg(arg_map, args, 'schedule', sched.name.to_s)
    # construction left at '--- No Change ---'

    @measure.run(model, runner, arg_map)
    result = runner.result
    show_output(result)
    assert_equal 'Success', result.value.valueName
    assert site_surf.construction.empty?,  'Construction should not have been set'
    assert !site_surf.transmittanceSchedule.empty?
    assert !bldg_surf.transmittanceSchedule.empty?
  end
end
