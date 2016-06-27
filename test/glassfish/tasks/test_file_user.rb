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

class Redfish::Tasks::Glassfish::TestFileUser < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {
      'auth_realms' =>
        {
          'file' =>
            {
              'classname' => 'com.sun.enterprise.security.auth.realm.file.FileRealm',
              'users' => {'admin' => {'groups' => %w(A B), 'password' => 'X'}}
            }
        }
    }

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-auth-realm'),
                                 equals(%w(--classname com.sun.enterprise.security.auth.realm.file.FileRealm file)),
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname file)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname file)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('create-file-user'),
                                 equals(%w(--authrealmname file --groups A:B admin)),
                                 has_key(:domain_password_file)).
      returns('')

    perform_interpret(context, data, true, :create, :additional_task_count => 1, :additional_unchanged_task_count => 1)
  end

  def test_interpret_create_when_exists
    data = {
      'auth_realms' =>
        {
          'file' =>
            {
              'classname' => 'com.sun.enterprise.security.auth.realm.file.FileRealm',
              'users' => {'admin' => {'groups' => %w(A B), 'password' => 'X'}}
            }
        }
    }

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-auth-realm'),
                                 equals(%w(--classname com.sun.enterprise.security.auth.realm.file.FileRealm file)),
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname file)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\n")
    executor.expects(:exec).with(equals(context),
                                 equals('list-file-groups'),
                                 equals(%w(--authrealmname file --name admin)),
                                 equals(:terse => true, :echo => false)).
      returns("A\nB\n")
    executor.expects(:exec).with(equals(context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname file)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\n")

    perform_interpret(context, data, false, :create, :additional_task_count => 1, :additional_unchanged_task_count => 1)
  end

  def test_interpret_create_and_delete
    data = {
      'auth_realms' =>
        {
          'file' =>
            {
              'classname' => 'com.sun.enterprise.security.auth.realm.file.FileRealm',
              'users' =>
                {
                  'admin' => {'groups' => %w(A B), 'password' => 'X'},
                  'joe' => {'groups' => %w(A B), 'password' => 'X'}
                }
            }
        }
    }

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-auth-realm'),
                                 equals(%w(--classname com.sun.enterprise.security.auth.realm.file.FileRealm file)),
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname file)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\nfred\n").
      at_least(2)
    executor.expects(:exec).with(equals(context),
                                 equals('list-file-groups'),
                                 equals(%w(--authrealmname file --name admin)),
                                 equals(:terse => true, :echo => false)).
      returns("A\nB\n")
    executor.expects(:exec).with(equals(context),
                                 equals('create-file-user'),
                                 equals(%w(--authrealmname file --groups A:B joe)),
                                 has_key(:domain_password_file)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('delete-file-user'),
                                 equals(%w(--authrealmname file fred)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create, :additional_task_count => 3, :additional_unchanged_task_count => 1)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'

    assert_equal t.to_s, 'file_user[admin-realm::admin]'
  end

  def test_create_when_no_such_user
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-file-user'),
                                 equals(%w(--authrealmname admin-realm admin)),
                                 has_key(:domain_password_file)).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.perform_action(:create)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_create_with_groups_when_no_such_user
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-file-user'),
                                 equals(%w(--authrealmname admin-realm --groups A:B admin)),
                                 has_key(:domain_password_file)).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.groups = %w(A B)
    t.perform_action(:create)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_user_needs_update
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-groups'),
                                 equals(%w(--authrealmname admin-realm --name admin)),
                                 equals(:terse => true, :echo => false)).
      returns("some-group-to-delete\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('update-file-user'),
                                 equals(['--authrealmname', 'admin-realm', 'admin']),
                                 has_key(:domain_password_file)).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.perform_action(:create)

    assert t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_user_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-groups'),
                                 equals(%w(--authrealmname admin-realm --name admin)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.perform_action(:create)

    assert !t.context.restart_required?

    executor = Redfish::Executor.new
    t = new_task(executor)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_user_exists
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns("admin\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-file-user'),
                                 equals(%w(--authrealmname admin-realm admin)),
                                 equals({})).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.perform_action(:destroy)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_destroy_when_user_no_exist
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    assert !t.context.restart_required?

    t.realm_name = 'admin-realm'
    t.username = 'admin'
    t.password = 'secret'
    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(admin vanilla)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns("vanilla\nadmin\nother\n").
      at_least(2)

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-file-user'),
                                 equals(%w(--authrealmname admin-realm other)),
                                 equals({})).
      returns('')

    t.realm_name = 'admin-realm'
    t.expected = existing

    t.perform_action(:clean)

    ensure_task_updated_by_last_action(t)
  end

  def test_cleaner_not_updated_if_no_clean_actions
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(admin vanilla)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-file-users'),
                                 equals(%w(--authrealmname admin-realm)),
                                 equals(:terse => true, :echo => false)).
      returns("vanilla\nadmin\n")

    t.realm_name = 'admin-realm'
    t.expected = existing

    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end
end
