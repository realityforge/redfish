require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJdbcResource < Redfish::TestCase
  def test_create_no_cache_and_not_present
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

  def test_create_no_cache_and_present
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

    get_expected_key_values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["resources.jdbc-resource.jdbc/MyDB.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("resources.jdbc-resource.jdbc/MyDB.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_no_cache_and_present_but_modified
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

    values = get_expected_key_values
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

  def test_create_cache_and_no_present
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

  def test_create_cache_and_present_but_modified
    cache_values = get_expected_cache_values

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

  def test_create_cache_and_present
    cache_values = get_expected_cache_values

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

  def test_delete_no_cache_and_not_present
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

  def test_delete_no_cache_and_present
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

  def test_delete_cache_and_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'jdbc/MyDB'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('resources.jdbc-resource.jdbc/MyDB.'), false
  end

  def test_delete_cache_and_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = get_expected_cache_values

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
    get_expected_cache_values.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def get_expected_key_values
    {
      'description' => 'Audit DB',
      'enabled' => 'true',
      'pool-name' => 'MyDBPool',
      'deployment-order' => '100'
    }
  end

  def get_expected_cache_values
    cache_values = {}

    get_expected_key_values.each_pair do |k, v|
      cache_values["resources.jdbc-resource.jdbc/MyDB.#{k}"] = "#{v}"
    end
    cache_values
  end

  def new_task(executor)
    t = Redfish::Tasks::JdbcResource.new
    t.context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
    t
  end
end
