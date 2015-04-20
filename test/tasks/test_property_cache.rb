require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestPropertyCache < Redfish::Tasks::BaseTaskTest
  def test_create_no_existing
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, false
    t.perform_action(:create)
    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_create_existing_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('a' => '-1')

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, true
    t.perform_action(:create)
    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_create_existing_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('a' => '1', 'b' => '2', 'c.d.e' => '345')

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, true
    t.perform_action(:create)
    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_destroy
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('a' => '1', 'b' => '2', 'c.d.e' => '345')

    assert_equal t.context.property_cache?, true
    t.perform_action(:destroy)
    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache?, false
  end

  def test_destroy_no_existing
    executor = Redfish::Executor.new
    t = new_task(executor)

    assert_equal t.context.property_cache?, false
    t.perform_action(:destroy)
    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache?, false
  end
end
