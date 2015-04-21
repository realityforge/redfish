require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJdbcResource < Redfish::Tasks::BaseTaskTest
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(["#{property_prefix}deployment-order"]),
                                 equals(:terse => true, :echo => false)).
      returns("resources.jdbc-resource.jdbc/MyDB.deployment-order=100\n")

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

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

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

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
                                 equals(["#{property_prefix}enabled=true"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(["#{property_prefix}property.Blah"]),
                                 equals(:terse => true, :echo => false)).
      returns("resources.jdbc-resource.jdbc/MyDB.property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}enabled"] = 'false'
    cache_values["#{property_prefix}description"] = 'XXX'
    cache_values["#{property_prefix}deployment-order"] = '101'

    # This property should be removed
    cache_values["#{property_prefix}property.Blah"] = 'X'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}description=Audit DB"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}enabled=true"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present
    t = new_task

    t.context.cache_properties(expected_properties)

    t.options = resource_parameters

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)

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

    ensure_task_not_updated_by_last_action(t)
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

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'jdbc/MyDB'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'resources.jdbc-resource.jdbc/MyDB.'
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

  # Resource parameters
  def resource_parameters
    {
      'name' => 'jdbc/MyDB',
      'enabled' => 'true',
      'connectionpoolid' => 'MyDBPool',
      'description' => 'Audit DB',
      'deploymentorder' => 100
    }
  end
end
