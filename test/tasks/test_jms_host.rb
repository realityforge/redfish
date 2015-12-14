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

class Redfish::Tasks::TestJmsHost < Redfish::Tasks::BaseTaskTest
  def test_interpret_create
    data = {'jms_hosts' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-jms-host'),
                                 equals(['--mqhost', 'mq.example.com', '--mqport', '99', '--mquser', 'god', '--mqpassword', 'secret', 'MyJmsHost']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('set'),
                                 equals(["#{property_prefix}lazy-init=false"]),
                                 equals(:terse => true, :echo => false))

    # Additional set
    perform_interpret(context, data, true, :create, :additional_task_count => 1)
  end

  def test_interpret_create_when_exists
    data = {'jms_hosts' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, to_properties_content)

    perform_interpret(context, data, false, :create)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'jms_host[MyJmsHost]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jms-hosts'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(["#{property_prefix}lazy-init"]),
                                 equals(:terse => true, :echo => false)).
        returns("#{property_prefix}lazy-init=true")
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jms-host'),
                                 equals(['--mqhost', 'mq.example.com', '--mqport', '99', '--mquser', 'god', '--mqpassword', 'secret', 'MyJmsHost']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}lazy-init=false"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jms-hosts'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyJmsHost\n")

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

    executor.expects(:exec).with(equals(t.context), equals('list-jms-hosts'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyJmsHost\n")

    values = expected_local_properties
    values['port'] = '101'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}port=99"]),
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
                                 equals('create-jms-host'),
                                 equals(%w(--mqhost mq.example.com --mqport 99 --mquser god --mqpassword secret MyJmsHost)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}lazy-init=false"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}port"] = '101'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}port=99"]),
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

    t.options = {'name' => 'MyJmsHost'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jms-hosts'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyJmsHost'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jms-hosts'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyJmsHost\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jms-host'),
                                 equals(['MyJmsHost']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyJmsHost'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyJmsHost'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jms-host'),
                                 equals(['MyJmsHost']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'configs.config.server-config.jms-service.jms-host.MyJmsHost.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'host' => 'mq.example.com',
      'port' => '99',
      'admin-user-name' => 'god',
      'admin-password' => 'secret',
      'lazy-init' => 'false'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyJmsHost',
      'host' => 'mq.example.com',
      'port' => 99,
      'admin_username' => 'god',
      'admin_password' => 'secret',
      'lazy_init' => false
    }
  end
end
