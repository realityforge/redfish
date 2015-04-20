require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestCustomResource < Redfish::TestCase
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context), equals('list-custom-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-custom-resource'),
                                 equals(['--enabled', 'true', '--restype', 'java.lang.String', '--factoryclass', 'org.glassfish.resources.custom.factory.PrimitivesAndStringFactory', '--description', 'My Env Setting', 'myapp/env/Setting']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(['resources.custom-resource.myapp/env/Setting.deployment-order']),
                                 equals(:terse => true, :echo => false)).
      returns("resources.custom-resource.myapp/env/Setting.deployment-order=100\n")

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context), equals('list-custom-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myapp/env/Setting\n")
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.custom-resource.myapp/env/Setting.property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.custom-resource.myapp/env/Setting.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.custom-resource.myapp/env/Setting.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context), equals('list-custom-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myapp/env/Setting\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.custom-resource.myapp/env/Setting.property.*)), equals(:terse => true, :echo => false)).
      returns("resources.custom-resource.myapp/env/Setting.property.Blah=Y\n")

    values = expected_local_properties
    values['deployment-order'] = '101'
    values['enabled'] = 'false'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.custom-resource.myapp/env/Setting.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.custom-resource.myapp/env/Setting.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.enabled=true']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.deployment-order=100']),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(['resources.custom-resource.myapp/env/Setting.property.Blah']),
                                 equals(:terse => true, :echo => false)).
      returns("resources.custom-resource.myapp/env/Setting.property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.property.Blah=']),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-custom-resource'),
                                 equals(['--enabled', 'true', '--restype', 'java.lang.String', '--factoryclass', 'org.glassfish.resources.custom.factory.PrimitivesAndStringFactory', '--description', 'My Env Setting', 'myapp/env/Setting']),
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

    cache_values['resources.custom-resource.myapp/env/Setting.enabled'] = 'false'
    cache_values['resources.custom-resource.myapp/env/Setting.description'] = 'XXX'
    cache_values['resources.custom-resource.myapp/env/Setting.deployment-order'] = '101'

    # This property should be removed
    cache_values['resources.custom-resource.myapp/env/Setting.property.Blah'] = 'X'

    t.context.cache_properties(cache_values)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.property.Blah=']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.deployment-order=100']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.description=My Env Setting']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.custom-resource.myapp/env/Setting.enabled=true']),
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

    do_set_params(t)

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myapp/env/Setting'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-custom-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myapp/env/Setting'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-custom-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("myapp/env/Setting\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-custom-resource'),
                                 equals(['myapp/env/Setting']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
  end

  def test_delete_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'myapp/env/Setting'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('resources.custom-resource.myapp/env/Setting.'), false
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties

    t.context.cache_properties(cache_values)
    t.options = {'name' => 'myapp/env/Setting'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-custom-resource'),
                                 equals(['myapp/env/Setting']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache.any_property_start_with?('resources.custom-resource.myapp/env/Setting.'), false
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
      cache_values["resources.custom-resource.myapp/env/Setting.#{k}"] = "#{v}"
    end
    cache_values
  end

  def do_set_params(t)
    t.options = params
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    p = params
    {
      'description' => p['description'],
      'enabled' => p['enabled'],
      'factory-class' => 'org.glassfish.resources.custom.factory.PrimitivesAndStringFactory',
      'res-type' => p['restype'],
      'deployment-order' => p['deploymentorder'].to_s
    }
  end

  # Resource parameters
  def params
    {'name' => 'myapp/env/Setting',
     'enabled' => 'true',
     'restype' => 'java.lang.String',
     'description' => 'My Env Setting',
     'deploymentorder' => 100}
  end

  def new_task(executor)
    t = Redfish::Tasks::CustomResource.new
    t.context = create_simple_context(executor)
    t
  end
end
