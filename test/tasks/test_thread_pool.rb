require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestThreadPool < Redfish::TestCase
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-threadpool'),
                                 equals(['--maxthreadpoolsize', '100', '--minthreadpoolsize', '10', '--idletimeout', '850', '--maxqueuesize', '4000', 'myThreadPool']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, true
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThreadPool\n")

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThreadPool\n")

    values = expected_local_properties
    values['max-thread-pool-size'] = '101'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['configs.config.server-config.thread-pools.thread-pool.myThreadPool.max-thread-pool-size=100']),
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
                                 equals('create-threadpool'),
                                 equals(['--maxthreadpoolsize', '100', '--minthreadpoolsize', '10', '--idletimeout', '850', '--maxqueuesize', '4000', 'myThreadPool']),
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

    cache_values['configs.config.server-config.thread-pools.thread-pool.myThreadPool.max-thread-pool-size'] = '101'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['configs.config.server-config.thread-pools.thread-pool.myThreadPool.max-thread-pool-size=100']),
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

    t.options = {'name' => 'myThreadPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-threadpools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThreadPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-threadpools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("myThreadPool\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-threadpool'),
                                 equals(['myThreadPool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
  end

  def test_delete_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'myThreadPool'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('configs.config.server-config.thread-pools.thread-pool.myThreadPool.'), false
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties

    t.context.cache_properties(cache_values)
    t.options = {'name' => 'myThreadPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-threadpool'),
                                 equals(['myThreadPool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, true
    assert_equal t.context.property_cache.any_property_start_with?('configs.config.server-config.thread-pools.thread-pool.myThreadPool.'), false
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
      cache_values["configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}"] = "#{v}"
    end
    cache_values
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'idle-thread-timeout-seconds' => '850',
      'max-thread-pool-size' => '100',
      'min-thread-pool-size' => '10',
      'max-queue-size' => '4000'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'myThreadPool',
     'maxthreadpoolsize' => 100,
     'minthreadpoolsize' => 10,
     'idletimeout' => 850,
     'maxqueuesize' => 4000
    }
  end

  def new_task(executor)
    t = Redfish::Tasks::ThreadPool.new
    t.context = create_simple_context(executor)
    t
  end
end
