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

class Redfish::TestExecutor < Redfish::TestCase
  def test_asadmin_script
    executor = Redfish::Executor.new
    assert_equal '/opt/payara-4.1.151/glassfish/bin/asadmin', executor.send(:asadmin_script, new_context(executor))
  end

  def test_build_command
    executor = Redfish::Executor.new
    context_1 = new_context(executor)
    assert_equal %w(/opt/payara-4.1.151/glassfish/bin/asadmin --terse=true --echo=false --user admin --port 4848 set a=b),
                 executor.build_command(context_1, 'set', ['a=b'], :terse => true, :echo => false)

    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   nil,
                                   :authbind_executable => '/usr/bin/authbind')

    assert_equal %w(/usr/bin/authbind --deep /opt/payara-4.1.151/glassfish/bin/asadmin --terse=true --echo=false --user admin --port 4848 set a=b),
                 executor.build_command(context, 'set', ['a=b'], :terse => true, :echo => false)

    Etc.expects(:getlogin).returns('bob')

    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   nil,
                                   :domains_directory => test_domains_dir,
                                   :system_user => 'glassfish',
                                   :system_group => 'glassfish-group')
    FileUtils.mkdir_p File.dirname(context.domain_password_file_location)
    FileUtils.touch context.domain_password_file_location
    assert_equal %W(/usr/bin/sudo -u glassfish -g glassfish-group /opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=false --user admin --passwordfile=#{context.domain_password_file_location} --secure --port 4848 set a=b),
                 executor.build_command(context,
                                        'set',
                                        ['a=b'],
                                        {})
  end

  def test_asadmin_command_prefix
    executor = Redfish::Executor.new
    assert_equal %w(--terse=false --echo=true --user admin --port 4848),
                 executor.send(:asadmin_command_prefix, new_context(executor))
    assert_equal %w(--terse=true --echo=false --user admin --port 4848),
                 executor.send(:asadmin_command_prefix, new_context(executor), :terse => true, :echo => false)

    context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, true, 'admin', nil, :domains_directory => test_domains_dir)
    FileUtils.mkdir_p File.dirname(context.domain_password_file_location)
    FileUtils.touch context.domain_password_file_location
    assert_equal %W(--terse=false --echo=false --user admin --passwordfile=#{context.domain_password_file_location} --secure --port 4848),
                 executor.send(:asadmin_command_prefix,
                               context)
  end

  def test_needs_user_change?
    executor = Redfish::Executor.new
    assert_equal false, executor.send(:needs_user_change?, new_context(executor))
    context_with_users =
      Redfish::Context.new(executor,
                           '/opt/payara-4.1.151/',
                           'domain1',
                           4848,
                           false,
                           'admin',
                           nil,
                           :system_user => 'glassfish',
                           :system_group => 'glassfish-group')

    Etc.expects(:getlogin).returns('bob')

    assert_equal true, executor.send(:needs_user_change?, context_with_users)


    Etc.expects(:getlogin).returns('glassfish')
    group = 'group'
    group.expects(:name).returns(group)
    Etc.expects(:group).returns(group)

    assert_equal true, executor.send(:needs_user_change?, context_with_users)

    Etc.expects(:getlogin).returns('glassfish')
    group = 'glassfish-group'
    group.expects(:name).returns(group)
    Etc.expects(:group).returns(group)

    assert_equal false, executor.send(:needs_user_change?, context_with_users)
  end

  def test_exec
    executor = Redfish::Executor.new

    cmd = %w(/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --port 4848 set a=1:b=2)
    IO.expects(:popen).with(equals(cmd), equals('r'), anything)
    executor.expects(:last_exitstatus).returns(0)

    executor.exec(new_context(executor), 'set', ['a=1:b=2'])
  end

  def new_context(executor)
    create_simple_context(executor, :terse => false, :echo => true)
  end
end
