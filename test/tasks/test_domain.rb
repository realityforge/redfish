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

class Redfish::Tasks::TestDomain < Redfish::Tasks::BaseTaskTest
  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    assert_equal t.to_s, 'domain[name=domain1 dir=/opt/payara-4.1.151/glassfish/domains/domain1]'
  end

  def test_create_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor,
                                                    :domains_directory => test_domains_dir,
                                                    :system_user => 'bob',
                                                    :system_group => 'bobgrp'))

    FileUtils.expects(:chown).with(equals('bob'),equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib")).returns('')
    FileUtils.expects(:chown).with(equals('bob'),equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib/ext")).returns('')
    FileUtils.expects(:chown).with(equals('bob'),equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin")).returns('')
    FileUtils.expects(:chown).with(equals('bob'),equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin")).returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=false --domaindir #{test_domains_dir} --template payara --keytooloptions CN=MyHost.example.com --domainproperties domain.adminPort=4848:domain.instancePort=1:domain.jmxPort=1:http.ssl.port=1:java.debugger.port=1:jms.port=1:orb.listener.port=1:orb.mutualauth.port=1:orb.ssl.port=1:osgi.shell.telnet.port=1 domain1)),
                                 equals({})).
      returns('')

    t.template = 'payara'
    t.common_name = 'MyHost.example.com'

    props = {}

    %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port).each do |key|
      props[key] = 1
      props[key] = t.context.domain_admin_port if key == 'domain.adminPort'
    end
    t.properties = props
    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    assert File.directory?("#{test_domains_dir}/domain1/bin")
    assert File.directory?("#{test_domains_dir}/domain1/lib")
    assert File.directory?("#{test_domains_dir}/domain1/lib/ext")
    assert File.file?("#{test_domains_dir}/domain1/bin/asadmin")

    cmd_script = IO.read("#{test_domains_dir}/domain1/bin/asadmin")
    assert_equal cmd_script, <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --port 4848 "$@"
    CMD
  end

  def test_create_with_most_common_options
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=false --domaindir #{test_domains_dir} --domainproperties domain.adminPort=4848 domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_with_mismatched_aadmin_port
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.properties = {'domain.adminPort' => t.context.domain_admin_port + 1}
    begin
      t.perform_action(:create)
      fail
    rescue Exception => e
      assert_equal e.to_s, "Domain property 'domain.adminPort' is set to '4849' which does not match context configuration value of '4848'"
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_with_unknown_property
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.properties = {'x' => 'y'}
    begin
      t.perform_action(:create)
      fail
    rescue Exception => e
      assert_equal e.to_s, "Unknown domain property 'x' specified."
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_when_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    FileUtils.mkdir_p(t.context.domain_directory)

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-domain'),
                                 equals(%W(--domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    FileUtils.mkdir_p(t.context.domain_directory)

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_start_when_not_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')
    executor.expects(:exec).with(equals(t.context),
                                 equals('start-domain'),
                                 equals(%W(--domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:start)

    ensure_task_updated_by_last_action(t)
  end

  def test_start_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running')

    t.perform_action(:start)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_stop_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running')
    executor.expects(:exec).with(equals(t.context),
                                 equals('stop-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:stop)

    ensure_task_updated_by_last_action(t)
  end

  def test_stop_when_not_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')

    t.perform_action(:stop)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_restart
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :domains_directory => test_domains_dir))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.perform_action(:restart)

    ensure_task_updated_by_last_action(t)
  end
end
