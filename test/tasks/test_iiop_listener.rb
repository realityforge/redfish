require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestIiopListener < Redfish::TestCase
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-iiop-listeners'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-iiop-listener'),
                                 equals(['--listeneraddress', '127.0.0.1', '--iiopport', '1072', '--securityenabled', 'false', '--enabled', 'true', 'myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-iiop-listeners'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["configs.config.server-config.iiop-service.iiop-listener.myThing.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("configs.config.server-config.iiop-service.iiop-listener.myThing.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(configs.config.server-config.iiop-service.iiop-listener.myThing.property.*)), equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-iiop-listeners'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    values = expected_local_properties
    values['port'] = '101'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["configs.config.server-config.iiop-service.iiop-listener.myThing.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("configs.config.server-config.iiop-service.iiop-listener.myThing.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['configs.config.server-config.iiop-service.iiop-listener.myThing.port=1072']),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%w(configs.config.server-config.iiop-service.iiop-listener.myThing.property.*)),
                                 equals(:terse => true, :echo => false)).
      returns('configs.config.server-config.iiop-service.iiop-listener.myThing.property.DeleteMe=X')

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%w(configs.config.server-config.iiop-service.iiop-listener.myThing.property.DeleteMe)),
                                 equals(:terse => true, :echo => false)).
        returns('configs.config.server-config.iiop-service.iiop-listener.myThing.property.DeleteMe=X')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(%w(configs.config.server-config.iiop-service.iiop-listener.myThing.property.DeleteMe=)),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-iiop-listener'),
                                 equals(['--listeneraddress', '127.0.0.1', '--iiopport', '1072', '--securityenabled', 'false', '--enabled', 'true', 'myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values['configs.config.server-config.iiop-service.iiop-listener.myThing.port'] = '101'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['configs.config.server-config.iiop-service.iiop-listener.myThing.port=1072']),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true

    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-iiop-listeners'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-iiop-listeners'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("myThing\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-iiop-listener'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
  end

  def test_delete_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'myThing'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('configs.config.server-config.iiop-service.iiop-listener.myThing.'), false
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties

    t.context.cache_properties(cache_values)
    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-iiop-listener'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache.any_property_start_with?('configs.config.server-config.iiop-service.iiop-listener.myThing.'), false
  end

  protected

  def ensure_expected_cache_values(t)
    expected_properties.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def expected_properties
    cache_values = {}

    expected_local_properties.each_pair do |k, v|
      cache_values["configs.config.server-config.iiop-service.iiop-listener.myThing.#{k}"] = "#{v}"
    end
    cache_values
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'address' => '127.0.0.1',
      'port' => '1072',
      'enabled' => 'true',
      'security-enabled' => 'false'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'myThing',
      'address' => '127.0.0.1',
      'port' => 1072,
      'enabled' => 'true',
      'securityenabled' => 'false'
    }
  end

  def new_task(executor)
    t = Redfish::Tasks::IiopListener.new
    t.context = create_simple_context(executor)
    t
  end
end
