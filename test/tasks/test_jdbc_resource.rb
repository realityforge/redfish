require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJdbcResource < Redfish::TestCase
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.deployment-order']),
                                 equals(:terse => true, :echo => false)).
      returns("resources.jdbc-resource.jdbc/MyDB.deployment-order=100\n")

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("jdbc/MyDB\n")
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.jdbc-resource.jdbc/MyDB.property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.jdbc-resource.jdbc/MyDB.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.jdbc-resource.jdbc/MyDB.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("jdbc/MyDB\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.jdbc-resource.jdbc/MyDB.property.*)), equals(:terse => true, :echo => false)).
      returns("resources.jdbc-resource.jdbc/MyDB.property.Blah=Y\n")

    values = expected_local_properties
    values['deployment-order'] = '101'
    values['enabled'] = 'false'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.jdbc-resource.jdbc/MyDB.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.jdbc-resource.jdbc/MyDB.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.enabled=true']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.deployment-order=100']),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.property.Blah']),
                                 equals(:terse => true, :echo => false)).
      returns("resources.jdbc-resource.jdbc/MyDB.property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.property.Blah=']),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
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

    cache_values['resources.jdbc-resource.jdbc/MyDB.enabled'] = 'false'
    cache_values['resources.jdbc-resource.jdbc/MyDB.description'] = 'XXX'
    cache_values['resources.jdbc-resource.jdbc/MyDB.deployment-order'] = '101'

    # This property should be removed
    cache_values['resources.jdbc-resource.jdbc/MyDB.property.Blah'] = 'X'

    t.context.cache_properties(cache_values)

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.property.Blah=']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.deployment-order=100']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.description=Audit DB']),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.jdbc-resource.jdbc/MyDB.enabled=true']),
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

    t.options = {'name' => 'jdbc/MyDB',
                 'enabled' => 'true',
                 'connectionpoolid' => 'MyDBPool',
                 'description' => 'Audit DB',
                 'deploymentorder' => 100}

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("jdbc/MyDB\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
  end

  def test_delete_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'jdbc/MyDB'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('resources.jdbc-resource.jdbc/MyDB.'), false
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties

    t.context.cache_properties(cache_values)
    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache.any_property_start_with?('resources.jdbc-resource.jdbc/MyDB.'), false
  end

  protected

  def ensure_expected_cache_values(t)
    expected_properties.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'description' => 'Audit DB',
      'enabled' => 'true',
      'pool-name' => 'MyDBPool',
      'deployment-order' => '100'
    }
  end

  def expected_properties
    cache_values = {}

    expected_local_properties.each_pair do |k, v|
      cache_values["resources.jdbc-resource.jdbc/MyDB.#{k}"] = "#{v}"
    end
    cache_values
  end

  def new_task(executor)
    t = Redfish::Tasks::JdbcResource.new
    t.context = create_simple_context(executor)
    t
  end
end
