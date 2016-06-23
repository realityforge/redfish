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

require File.expand_path('../../../helper', __FILE__)

class Redfish::Tasks::Glassfish::TestJavamailResource < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'javamail_resources' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-javamail-resource'),
                                 equals(['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create, :additional_unchanged_task_count => 1)
  end

  def test_interpret_create_when_exists
    data = {'javamail_resources' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, to_properties_content)

    perform_interpret(context, data, false, :create, :additional_unchanged_task_count => expected_local_properties.size)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'javamail_resource[myThing]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-javamail-resource'),
                                 equals(['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
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

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-javamail-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("myThing\n")

    values = expected_local_properties
    values['transport-protocol'] = 'imap_other'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}transport-protocol=smtp2"]),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%W(#{property_prefix}property.*)),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.DeleteMe=X")

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%W(#{property_prefix}property.DeleteMe)),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.DeleteMe=X")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(%W(#{property_prefix}property.DeleteMe=)),
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
                                 equals('create-javamail-resource'),
                                 equals(['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values = expected_properties
    cache_values["#{property_prefix}transport-protocol"] = 'smtp3'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}transport-protocol=smtp2"]),
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

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-javamail-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-javamail-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("myThing\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-javamail-resource'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'myThing'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'myThing'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-javamail-resource'),
                                 equals(['myThing']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_interpret_create_and_delete
    data = {'javamail_resources' => resource_parameters_as_tree(:managed => true)}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    existing = %w(Element1 Element2)
    setup_interpreter_expects_with_fake_elements(executor, context, existing)

    executor.expects(:exec).with(equals(context),
                                 equals('create-javamail-resource'),
                                 equals(['--debug', 'true', '--enabled', 'true', '--description', 'Audit DB', '--mailhost', 'mail.example.com', '--mailuser', 'myUser', '--fromaddress', 'myUser@example.com', '--storeprotocol', 'imap', '--storeprotocolclass', 'com.sun.mail.imap.IMAPStore', '--transprotocol', 'smtp2', '--transprotocolclass', 'com.sun.mail.smtp.SMTPTransport2', 'myThing']),
                                 equals({})).
      returns('')

    existing.each do |element|
      executor.expects(:exec).with(equals(context),
                                   equals('delete-javamail-resource'),
                                   equals([element]),
                                   equals({})).
        returns('')
    end

    perform_interpret(context, data, true, :create, :additional_task_count => 1 + existing.size, :additional_unchanged_task_count => 1)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2 Element3)
    create_fake_elements(t.context, existing)

    t.expected = existing[1, existing.size]

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-javamail-resource'),
                                 equals([existing.first]),
                                 equals({})).
      returns('')

    t.perform_action(:clean)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t, "#{raw_property_prefix}#{existing.first}")
  end

  def test_cleaner_not_updated_if_no_clean_actions
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2 Element3)
    create_fake_elements(t.context, existing)

    t.expected = existing
    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end

  protected

  def property_prefix
    "#{raw_property_prefix}myThing."
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'host' => 'mail.example.com',
      'user' => 'myUser',
      'from' => 'myUser@example.com',
      'store-protocol' => 'imap',
      'store-protocol-class' => 'com.sun.mail.imap.IMAPStore',
      'transport-protocol' => 'smtp2',
      'transport-protocol-class' => 'com.sun.mail.smtp.SMTPTransport2',
      'enabled' => 'true',
      'debug' => 'true',
      'description' => 'Audit DB',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'myThing',
      'host' => 'mail.example.com',
      'user' => 'myUser',
      'from' => 'myUser@example.com',
      'store_protocol' => 'imap',
      'store_protocol_class' => 'com.sun.mail.imap.IMAPStore',
      'transport_protocol' => 'smtp2',
      'transport_protocol_class' => 'com.sun.mail.smtp.SMTPTransport2',
      'enabled' => 'true',
      'debug' => 'true',
      'description' => 'Audit DB',
      'deployment_order' => 100
    }
  end
end
