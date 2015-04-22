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

class Redfish::Tasks::TestWebEnvEntry < Redfish::Tasks::BaseTaskTest
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-web-env-entry'), equals(%w(MyApp)), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-web-env-entry'),
                                 equals(['--name', 'MyEntry', '--type', 'java.lang.String', '--description', 'My Entry Desc', '--value', 'Blah', '--ignoreDescriptorItem=false', 'MyApp']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-web-env-entry'), equals(%w(MyApp)), equals(:terse => true, :echo => false)).
      returns("MyEntry (java.lang.String) = x ignoreDescriptorItem=true //(description not specified)\n")

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

    executor.expects(:exec).with(equals(t.context), equals('list-web-env-entry'), equals(%w(MyApp)), equals(:terse => true, :echo => false)).
      returns("MyEntry (null) = null ignoreDescriptorItem=false //(description not specified)\n")

    values = expected_local_properties
    values['env-entry-value'] = 'NotTheBaby'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}env-entry-value=Blah"]),
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
                                 equals('set-web-env-entry'),
                                 equals(['--name', 'MyEntry', '--type', 'java.lang.String', '--description', 'My Entry Desc', '--value', 'Blah', '--ignoreDescriptorItem=false', 'MyApp']),
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

    cache_values["#{property_prefix}env-entry-value"] = 'X'
    cache_values["#{property_prefix}description"] = 'XXX'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}env-entry-value=Blah"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}description=My Entry Desc"]),
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

    t.options = {'application' => 'MyApp', 'name' => 'MyEntry'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-web-env-entry'),
                                 equals(['MyApp']),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'application' => 'MyApp', 'name' => 'MyEntry'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-web-env-entry'),
                                 equals(['MyApp']),
                                 equals({:terse => true, :echo => false})).
      returns("MyEntry (null)\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('unset-web-env-entry'),
                                 equals(['--name', 'MyEntry', 'MyApp']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'application' => 'MyApp', 'name' => 'MyEntry'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'application' => 'MyApp', 'name' => 'MyEntry'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('unset-web-env-entry'),
                                 equals(['--name', 'MyEntry', 'MyApp']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'applications.application.MyApp.module.MyApp.engine.web.web-module-config.env-entry.MyEntry.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'ignore-descriptor-item' => 'false',
      'env-entry-type' => 'java.lang.String',
      'env-entry-value' => 'Blah',
      'description' => 'My Entry Desc'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyEntry',
      'application' => 'MyApp',
      'type' => 'java.lang.String',
      'value' => 'Blah',
      'description' => 'My Entry Desc'
    }
  end
end