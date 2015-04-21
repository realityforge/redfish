require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestManagedScheduledExecutorService < Redfish::Tasks::BaseTaskTest
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-managed-scheduled-executor-services'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-managed-scheduled-executor-service'),
                                 equals(['--enabled', 'true', '--contextinfoenabled', 'true', '--contextinfo', 'Classloader,JNDI,Security', '--threadpriority', '6', '--corepoolsize', '4', '--hungafterseconds', '0', '--keepaliveseconds', '60', '--longrunningtasks', 'false', '--maximumpoolsize', '2147483647', '--threadlifetimeseconds', '0', '--property', 'SomeKey=SomeValue', '--description', 'Blah blah', 'MyScheduledExecutorService']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(["#{property_prefix}deployment-order"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}deployment-order=100\n")

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-managed-scheduled-executor-services'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyScheduledExecutorService\n")
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-managed-scheduled-executor-services'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyScheduledExecutorService\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=Y\n")

    values = expected_local_properties
    values['deployment-order'] = '101'
    values['enabled'] = 'false'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
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
      returns("#{property_prefix}property.Blah=X\n")

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
                                 equals('create-managed-scheduled-executor-service'),
                                 equals(['--enabled', 'true', '--contextinfoenabled', 'true', '--contextinfo', 'Classloader,JNDI,Security', '--threadpriority', '6', '--corepoolsize', '4', '--hungafterseconds', '0', '--keepaliveseconds', '60', '--longrunningtasks', 'false', '--maximumpoolsize', '2147483647', '--threadlifetimeseconds', '0', '--property', 'SomeKey=SomeValue', '--description', 'Blah blah', 'MyScheduledExecutorService']),
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
                                 equals(["#{property_prefix}description=Blah blah"]),
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

    t.options = {'name' => 'MyScheduledExecutorService'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-managed-scheduled-executor-services'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyScheduledExecutorService'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-managed-scheduled-executor-services'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyScheduledExecutorService\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-managed-scheduled-executor-service'),
                                 equals(['MyScheduledExecutorService']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyScheduledExecutorService'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyScheduledExecutorService'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-managed-scheduled-executor-service'),
                                 equals(['MyScheduledExecutorService']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'resources.managed-scheduled-executor-service.MyScheduledExecutorService.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'description' => 'Blah blah',
      'enabled' => 'true',
      'context-info-enabled' => 'true',
      'context-info' => 'Classloader,JNDI,Security',
      'property.SomeKey' => 'SomeValue',
      'thread-priority' => '6',
      'core-pool-size' => '4',
      'hung-after-seconds' => '0',
      'keep-alive-seconds' => '60',
      'long-running-tasks' => 'false',
      'maximum-pool-size' => '2147483647',
      'thread-lifetime-seconds' => '0',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyScheduledExecutorService',
      'enabled' => 'true',
      'thread_priority' => 6,
      'context_info_enabled' => 'true',
      'context_info' => 'Classloader,JNDI,Security',
      'description' => 'Blah blah',
      'properties' => {'SomeKey' => 'SomeValue'},
      'core_pool_size' => 4,
      'hung_after_seconds' => 0,
      'keep_alive_seconds' => 60,
      'long_running_tasks' => false,
      'maximum_pool_size' => 2147483647,
      'thread_lifetime_seconds' => 0,
      'deployment_order' => 100
    }
  end
end
