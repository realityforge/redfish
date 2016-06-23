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

class Redfish::Tasks::Glassfish::TestLibrary < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'libraries' => {'jtds' => {'file' => '/opt/jtds/jtds-1.3.1.jar', 'library_type' => 'ext'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('add-library'),
                                 equals(%w(--type ext --upload false /opt/jtds/jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create)
  end

  def test_interpret_create_when_exists
    data = {'libraries' => {'jtds' => {'file' => '/opt/jtds/jtds-1.3.1.jar', 'library_type' => 'ext'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('jtds-1.3.1.jar')

    perform_interpret(context, data, false, :create)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'

    assert_equal t.to_s, 'library[ext::/opt/jtds/jtds-1.3.1.jar]'
  end

  def test_create_when_no_such_library
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('add-library'),
                                 equals(%w(--type ext --upload false /opt/jtds/jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    assert !t.context.restart_required?

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:create)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_no_such_library_and_require_restart_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('add-library'),
                                 equals(%w(--type ext --upload false /opt/jtds/jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    assert !t.context.restart_required?

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.require_restart = true
    t.perform_action(:create)

    assert t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_library_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("jtds-1.3.1.jar\n")

    assert !t.context.restart_required?

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:create)

    assert !t.context.restart_required?

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_library_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("jtds-1.3.1.jar\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('remove-library'),
                                 equals(%w(--type ext jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    assert !t.context.restart_required?

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:destroy)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_destroy_when_library_exists_and_require_restart_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("jtds-1.3.1.jar\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('remove-library'),
                                 equals(%w(--type ext jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    assert !t.context.restart_required?

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.require_restart = true
    t.perform_action(:destroy)

    assert t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_destroy_when_library_no_exist
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.file = '/opt/jtds/jtds-1.3.1.jar'
    t.library_type = 'ext'
    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_interpret_create_and_delete
    data = {'libraries' => {'managed' => true,
                            'jtds' => {'file' => '/opt/jtds/jtds-1.3.1.jar', 'library_type' => 'ext'},
                            'activemq' => {'file' => '/opt/jtds/activemq-1.3.1.jar', 'library_type' => 'ext'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    todelete = %w(other.jar pgsql.jar)
    existing = todelete + %w(activemq-1.3.1.jar)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-libraries'),
                                 equals(%w(--type common)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('list-libraries'),
                                 equals(%w(--type app)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("#{existing.join("\n")}\n").
      at_least(2)

    executor.expects(:exec).with(equals(context),
                                 equals('add-library'),
                                 equals(%w(--type ext --upload false /opt/jtds/jtds-1.3.1.jar)),
                                 equals({})).
      returns('')

    todelete.each do |element|
      executor.expects(:exec).with(equals(context),
                                   equals('remove-library'),
                                   equals(%W(--type ext #{element})),
                                   equals({})).
        returns('')
    end

    perform_interpret(context, data, true, :create, :additional_task_count => 1 + todelete.size, :additional_unchanged_task_count => 2 + 1)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(/opt/jtds/jtds-1.3.1.jar /opt/pgsql/pgsql.jar)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("other.jar\npgsql.jar\njtds-1.3.1.jar\n").
      at_least(2)

    executor.expects(:exec).with(equals(t.context),
                                 equals('remove-library'),
                                 equals(%w(--type ext other.jar)),
                                 equals({})).
      returns('')

    t.library_type = 'ext'
    t.expected = existing

    t.perform_action(:clean)

    ensure_task_updated_by_last_action(t)
  end

  def test_cleaner_not_updated_if_no_clean_actions
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(/opt/jtds/jtds-1.3.1.jar /opt/pgsql/pgsql.jar /opt/other/other.jar)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-libraries'),
                                 equals(%w(--type ext)),
                                 equals(:terse => true, :echo => false)).
      returns("other.jar\npgsql.jar\njtds-1.3.1.jar\n")

    t.library_type = 'ext'
    t.expected = existing
    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end
end
