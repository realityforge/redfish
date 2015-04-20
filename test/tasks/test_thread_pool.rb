require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestThreadPool < Redfish::TestCase
  def test_create_no_cache_and_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

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

  def test_create_no_cache_and_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThreadPool\n")

    get_expected_key_values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}=#{v}\n")
    end

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false
  end

  def test_create_no_cache_and_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThreadPool\n")

    values = get_expected_key_values
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

  def test_create_cache_and_no_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-threadpool'),
                                 equals(['--maxthreadpoolsize', '100', '--minthreadpoolsize', '10', '--idletimeout', '850', '--maxqueuesize', '4000', 'myThreadPool']),
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

    cache_values['configs.config.server-config.thread-pools.thread-pool.myThreadPool.max-thread-pool-size'] = '101'

    t.context.cache_properties(cache_values)

    do_set_params(t)

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['configs.config.server-config.thread-pools.thread-pool.myThreadPool.max-thread-pool-size=100']),
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

    do_set_params(t)

    t.perform_action(:create)

    assert_equal t.updated_by_last_action?, false

    ensure_expected_cache_values(t)
  end

  def test_delete_no_cache_and_not_present
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

  def test_delete_no_cache_and_present
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

  def test_delete_cache_and_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})
    t.options = {'name' => 'myThreadPool'}

    t.perform_action(:destroy)

    assert_equal t.updated_by_last_action?, false
    assert_equal t.context.property_cache.any_property_start_with?('configs.config.server-config.thread-pools.thread-pool.myThreadPool.'), false
  end

  def test_delete_cache_and_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = get_expected_cache_values

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
    get_expected_cache_values.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def get_expected_cache_values
    cache_values = {}

    get_expected_key_values.each_pair do |k, v|
      cache_values["configs.config.server-config.thread-pools.thread-pool.myThreadPool.#{k}"] = "#{v}"
    end
    cache_values
  end

  def do_set_params(t)
    t.options = params
  end

  def get_expected_key_values
    {
      'idle-thread-timeout-seconds' => '850',
      'max-thread-pool-size' => '100',
      'min-thread-pool-size' => '10',
      'max-queue-size' => '4000'
    }
  end

  def params
    {'name' => 'myThreadPool',
     'maxthreadpoolsize' => 100,
     'minthreadpoolsize' => 10,
     'idletimeout' => 850,
     'maxqueuesize' => 4000}
  end

  def new_task(executor)
    t = Redfish::Tasks::ThreadPool.new
    t.context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
    t
  end
end
