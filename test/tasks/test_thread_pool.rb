#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestThreadPool < Redfish::Tasks::BaseTaskTest
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

    ensure_task_updated_by_last_action(t)
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

    executor.expects(:exec).with(equals(t.context), equals('list-threadpools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThreadPool\n")

    values = expected_local_properties
    values['max-thread-pool-size'] = '101'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}max-thread-pool-size=100"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
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

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}max-thread-pool-size"] = '101'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}max-thread-pool-size=100"]),
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

    t.options = {'name' => 'myThreadPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-threadpools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
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

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'myThreadPool'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'myThreadPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-threadpool'),
                                 equals(['myThreadPool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'configs.config.server-config.thread-pools.thread-pool.myThreadPool.'
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
end