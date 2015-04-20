require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestAsadminTask < Redfish::TestCase
  class MyAsadminTask < Redfish::Tasks::AsadminTask
    attribute :properties, :kind_of => Hash, :default => {}
  end

  def test_load_properties
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals(%w(*)), equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    properties = t.send(:load_properties, '*')

    assert_equal properties['a'], '1'
    assert_equal properties['b'], '2'
    assert_equal properties['c.d.e'], '345'
  end

  def test_parse_properties
    executor = Redfish::Executor.new
    t = new_task(executor)

    properties = t.send(:parse_properties, "a=1\nb=2\nc.d.e=345")

    assert_equal properties['a'], '1'
    assert_equal properties['b'], '2'
    assert_equal properties['c.d.e'], '345'
  end

  def collect_property_sets_with_cache_present
    property_prefix = 'resources.jdbc-connection-pool.MyDbPool.'

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = {}
    cache_values["#{property_prefix}property.c"] = '3'

    t.context.cache_properties(cache_values)

    t.properties = {'a' => '1', 'b' => '2'}

    property_map = []

    t.send(:collect_property_sets, property_prefix, property_map)

    assert_equal property_map, {'property.a' => '1', 'property.b' => '2', 'property.c' => ''}
  end

  def collect_property_sets_with_no_cache_present
    property_prefix = 'resources.jdbc-connection-pool.MyDbPool.'

    executor = Redfish::Executor.new
    t = new_task(executor)

    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.jdbc-connection-pool.APool.property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.c=3\n")

    t.properties = {'a' => '1', 'b' => '2'}

    property_map = []

    t.send(:collect_property_sets, property_prefix, property_map)

    assert_equal property_map, {'property.a' => '1', 'property.b' => '2', 'property.c' => ''}
  end

  def new_task(executor)
    t = MyAsadminTask.new
    t.context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
    t
  end
end
