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

# noinspection RubyTooManyMethodsInspection
class Redfish::Tasks::Glassfish::TestDomain < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    assert_equal t.to_s, 'domain[name=domain1]'
  end

  def test_create_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor,
                                                    :system_user => 'bob',
                                                    :system_group => 'bobgrp'))

    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/lib/ext")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/docroot")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/tmp")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/prefs")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config/redfish.password")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin_stop")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin_start")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin_run")).returns('')
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/bin/asadmin_restart")).returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=true --nopassword=true --usemasterpassword=true --domaindir #{test_domains_dir} --template payara --keytooloptions CN=MyHost.example.com --domainproperties domain.adminPort=4848:domain.instancePort=1:domain.jmxPort=1:http.ssl.port=1:java.debugger.port=1:jms.port=1:orb.listener.port=1:orb.mutualauth.port=1:orb.ssl.port=1:osgi.shell.telnet.port=1 domain1)),
                                 has_key(:domain_password_file)).
      returns('')

    t.template = 'payara'
    t.common_name = 'MyHost.example.com'

    props = {}

    %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port).each do |key|
      props[key] = 1
      props[key] = t.context.domain_admin_port if key == 'domain.adminPort'
    end
    t.properties = props

    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/docroot"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/restrict.server.policy"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/javaee.server.policy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/autodeploy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/init-info"))

    gitkeep_file = "#{t.context.domain_directory}/config/.gitkeep"
    Dir.expects(:[]).with(equals("#{t.context.domain_directory}/**/.gitkeep")).returns([gitkeep_file])
    FileUtils.expects(:rm_f).with(equals(gitkeep_file))

    t.perform_action(:create)

    FileUtils.unstub(:rm_f)
    FileUtils.unstub(:rm_rf)

    ensure_task_updated_by_last_action(t)

    assert_domain_directories

    # Master password synthesized
    assert IO.read(t.context.domain_password_file_location) =~ /^AS_ADMIN_MASTERPASSWORD=.+\nAS_ADMIN_PASSWORD=\n$/

    ensure_domain_scripts_created(t)
  end

  def test_create_with_most_common_options
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=true --nopassword=true --usemasterpassword=true --domaindir #{test_domains_dir} --domainproperties domain.adminPort=4848 domain1)),
                                 has_key(:domain_password_file)).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_when_not_present_and_no_admin_password
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   nil,
                                   {
                                     :domains_directory => test_domains_dir,
                                     :domain_master_password => 'secret'
                                   }
    )

    t = new_task_with_context(context)

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=true --nopassword=true --usemasterpassword=true --domaindir #{test_domains_dir} --template payara --keytooloptions CN=MyHost.example.com --domainproperties domain.adminPort=4848:domain.instancePort=1:domain.jmxPort=1:http.ssl.port=1:java.debugger.port=1:jms.port=1:orb.listener.port=1:orb.mutualauth.port=1:orb.ssl.port=1:osgi.shell.telnet.port=1 domain1)),
                                 has_key(:domain_password_file)).
      returns('')

    t.template = 'payara'
    t.common_name = 'MyHost.example.com'

    props = {}

    %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port).each do |key|
      props[key] = 1
      props[key] = t.context.domain_admin_port if key == 'domain.adminPort'
    end
    t.properties = props

    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/docroot"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/restrict.server.policy"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/javaee.server.policy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/autodeploy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/init-info"))

    gitkeep_file = "#{t.context.domain_directory}/config/.gitkeep"
    Dir.expects(:[]).with(equals("#{t.context.domain_directory}/**/.gitkeep")).returns([gitkeep_file])
    FileUtils.expects(:rm_f).with(equals(gitkeep_file))

    t.perform_action(:create)

    FileUtils.unstub(:rm_f)
    FileUtils.unstub(:rm_rf)

    ensure_task_updated_by_last_action(t)

    assert_domain_directories

    assert_equal IO.read(context.domain_password_file_location), <<-CMD
AS_ADMIN_MASTERPASSWORD=secret
AS_ADMIN_PASSWORD=
    CMD

    ensure_domain_scripts_created(t)
  end

  def test_create_when_not_present_and_admin_password
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   'secret1',
                                   {
                                     :domains_directory => test_domains_dir,
                                     :domain_master_password => 'secret'
                                   }
    )

    t = new_task_with_context(context)

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-domain'),
                                 equals(%W(--checkports=false --savelogin=false --savemasterpassword=false --nopassword=false --usemasterpassword=true --domaindir #{test_domains_dir} --template payara --keytooloptions CN=MyHost.example.com --domainproperties domain.adminPort=4848:domain.instancePort=1:domain.jmxPort=1:http.ssl.port=1:java.debugger.port=1:jms.port=1:orb.listener.port=1:orb.mutualauth.port=1:orb.ssl.port=1:osgi.shell.telnet.port=1 domain1)),
                                 has_key(:domain_password_file)).
      returns('')

    t.template = 'payara'
    t.common_name = 'MyHost.example.com'

    props = {}

    %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port).each do |key|
      props[key] = 1
      props[key] = t.context.domain_admin_port if key == 'domain.adminPort'
    end
    t.properties = props

    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/docroot"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/restrict.server.policy"))
    FileUtils.expects(:rm_f).with(equals("#{t.context.domain_directory}/config/javaee.server.policy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/autodeploy"))
    FileUtils.expects(:rm_rf).with(equals("#{t.context.domain_directory}/init-info"))

    gitkeep_file = "#{t.context.domain_directory}/config/.gitkeep"
    Dir.expects(:[]).with(equals("#{t.context.domain_directory}/**/.gitkeep")).returns([gitkeep_file])
    FileUtils.expects(:rm_f).with(equals(gitkeep_file))

    t.perform_action(:create)

    FileUtils.unstub(:rm_f)
    FileUtils.unstub(:rm_rf)

    ensure_task_updated_by_last_action(t)

    assert_domain_directories

    assert_equal IO.read(context.domain_password_file_location), <<-CMD
AS_ADMIN_MASTERPASSWORD=secret
AS_ADMIN_PASSWORD=secret1
    CMD

    ensure_domain_scripts_created(t, true)
  end

  def test_create_with_mismatched_aadmin_port
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

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
    t = new_task_with_context(create_simple_context(executor))

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
    t = new_task_with_context(create_simple_context(executor))

    FileUtils.mkdir_p(t.context.domain_directory)

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_not_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_destroy_when_present
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

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
    t = new_task_with_context(create_simple_context(executor))

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

    assert !t.context.domain_started?

    t.perform_action(:start)

    assert t.context.domain_started?

    ensure_task_updated_by_last_action(t)
  end

  def test_start_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running')

    t.perform_action(:start)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_start_when_running_but_requires_restart
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 running, restart required to apply configuration changes')

    t.perform_action(:start)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_stop_when_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

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
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')

    t.perform_action(:stop)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_complete
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

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

    t.shutdown_on_complete = true
    t.context.domain_started!

    %W{ #{t.context.domain_directory}/config/.consolestate
        #{t.context.domain_directory}/config/.instancestate
        #{t.context.domain_directory}/config/pid
        #{t.context.domain_directory}/config/pid.prev
        #{t.context.domain_directory}/config/derby.log
        #{t.context.domain_directory}/config/lockfile
        #{t.context.domain_directory}/config/domain.xml.bak }.each do |file|
      FileUtils.expects(:rm_f).with(equals(file))
    end
    %W{ #{t.context.domain_directory}/autodeploy
        #{t.context.domain_directory}/config/init.conf
        #{t.context.domain_directory}/logs/server.log
        #{t.context.domain_directory}/imq
        #{t.context.domain_directory}/lib/databases/embedded_default }.each do |file|
      FileUtils.expects(:rm_rf).with(equals(file))
    end

    t.perform_action(:complete)

    FileUtils.unstub(:rm_f)
    FileUtils.unstub(:rm_rf)

    ensure_task_updated_by_last_action(t)
  end

  def test_complete_not_started_by_redfish
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    t.shutdown_on_complete = true

    t.perform_action(:complete)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_complete_not_shutdown_on_complete
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    t.shutdown_on_complete = false
    t.context.domain_started!

    t.perform_action(:complete)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_complete_not_running
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-domains'),
                                 equals(%W(--domaindir #{test_domains_dir})),
                                 equals({:terse => true, :echo => false})).
      returns('domain1 not running')

    t.shutdown_on_complete = true
    t.context.domain_started!

    t.perform_action(:complete)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_restart
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart)

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('_get-restart-required'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("true\n")
    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.context.require_restart!

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context_only
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')

    t.context.require_restart!

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    t.context_only = true

    t.perform_action(:restart_if_required)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_restart_if_required_using_context_only_not_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    t.context_only = true

    t.perform_action(:restart_if_required)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_restart_if_required_when_not_required
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    executor.expects(:exec).with(equals(t.context),
                                 equals('_get-restart-required'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("false\n")

    t.perform_action(:restart_if_required)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_active
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("http://127.0.0.1:4848#{path}"),
                                                  equals('admin'),
                                                  equals('password')).
        returns(true)
    end

    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_in_secure_domain
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   1234,
                                   true,
                                   'admin1',
                                   'password2',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("https://127.0.0.1:1234#{path}"),
                                                  equals('admin1'),
                                                  equals('password2')).
        returns(true)
    end

    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_when_not_active
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    s = sequence('main')

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)

    Kernel.expects(:sleep).with(equals(1)).in_sequence(s)

    %w(/ /management/domain/nodes /management/domain/applications).each do |path|
      t.expects(:is_url_responding_with_ok?).with(equals("http://127.0.0.1:4848#{path}"),
                                                  equals('admin'),
                                                  equals('password')).
        returns(true).
        in_sequence(s)
    end

    t.max_mx_wait_time = 1
    t.perform_action(:ensure_active)

    ensure_task_updated_by_last_action(t)
  end

  def test_ensure_active_when_not_active_in_time
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   false,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    s = sequence('main')

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)

    Kernel.expects(:sleep).with(equals(1)).in_sequence(s)

    t.expects(:is_url_responding_with_ok?).with(equals('http://127.0.0.1:4848/'),
                                                equals('admin'),
                                                equals('password')).
      returns(false).
      in_sequence(s)


    t.max_mx_wait_time = 1

    begin
      t.perform_action(:ensure_active)
    rescue => e
      assert_equal e.message, 'GlassFish failed to become operational'
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_enable_secure_admin
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir,
                                   :system_user => 'bob',
                                   :system_group => 'bobgrp')
    t = new_task_with_context(context)

    t.context.cache_properties({})

    executor.expects(:exec).with(equals(t.context),
                                 equals('enable-secure-admin'),
                                 equals([]),
                                 equals({:secure => false})).
      returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({:secure => false})).
      returns('')

    # Mock out the ensure active
    t.expects(:do_ensure_active)

    FileUtils.mkdir_p "#{test_domains_dir}/domain1/config"
    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals("#{test_domains_dir}/domain1/config/secure.marker")).returns('')

    t.perform_action(:enable_secure_admin)

    assert File.exist?("#{test_domains_dir}/domain1/config/secure.marker")

    # Cache should have been destroyed when action completed
    assert !context.property_cache?

    ensure_task_updated_by_last_action(t)
  end

  def test_enable_secure_admin_when_already_secure
    executor = Redfish::Executor.new
    context = Redfish::Context.new(executor,
                                   '/opt/payara-4.1.151/',
                                   'domain1',
                                   4848,
                                   true,
                                   'admin',
                                   'password',
                                   :domains_directory => test_domains_dir)
    t = new_task_with_context(context)

    t.context.cache_properties({})
    FileUtils.mkdir_p "#{test_domains_dir}/domain1/config"
    FileUtils.touch "#{test_domains_dir}/domain1/config/secure.marker"

    t.perform_action(:enable_secure_admin)

    # Cache should not have been destroyed as action did not cause update
    assert context.property_cache?

    ensure_task_not_updated_by_last_action(t)
  end

  def assert_domain_directories
    assert_domain_directory('bin', '755')
    assert_domain_directory('lib', '755')
    assert_domain_directory('lib/ext', '755')
    assert_domain_directory('docroot', '755')
    assert_domain_directory('tmp', '700')
    assert_domain_directory('prefs', '700')
  end

  def assert_domain_directory(filename, mode)
    assert_directory("#{test_domains_dir}/domain1/#{filename}", mode)
  end

  def assert_directory(filename, mode)
    assert File.directory?(filename)
    assert_file_mode(filename, mode)
  end

  def assert_domain_file(filename, mode)
    assert_file("#{test_domains_dir}/domain1/#{filename}", mode)
  end

  def assert_file(filename, mode)
    assert File.file?(filename)
    assert_file_mode(filename, mode)
  end

  def ensure_domain_scripts_created(t, secure = false)
    assert_domain_file('bin/asadmin', '700')
    assert_domain_file('bin/asadmin_stop', '700')
    assert_domain_file('bin/asadmin_start', '700')
    assert_domain_file('bin/asadmin_run', '700')
    assert_domain_file('bin/asadmin_restart', '700')

    assert_equal IO.read("#{test_domains_dir}/domain1/bin/asadmin"), <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} #{secure ? '--secure ' : ''}--port 4848 --host 127.0.0.1 "$@"
    CMD

    assert_equal IO.read("#{test_domains_dir}/domain1/bin/asadmin_stop"), <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} #{secure ? '--secure ' : ''}--port 4848 --host 127.0.0.1 stop-domain --domaindir #{test_domains_dir} \"$@\" #{t.context.domain_name}
    CMD
    assert_equal IO.read("#{test_domains_dir}/domain1/bin/asadmin_start"), <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} #{secure ? '--secure ' : ''}--port 4848 --host 127.0.0.1 start-domain --domaindir #{test_domains_dir} \"$@\" #{t.context.domain_name}
    CMD
    assert_equal IO.read("#{test_domains_dir}/domain1/bin/asadmin_run"), <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} #{secure ? '--secure ' : ''}--port 4848 --host 127.0.0.1 start-domain --domaindir #{test_domains_dir} --verbose=true \"$@\" #{t.context.domain_name}
    CMD
    assert_equal IO.read("#{test_domains_dir}/domain1/bin/asadmin_restart"), <<-CMD
#!/bin/sh

/opt/payara-4.1.151/glassfish/bin/asadmin --terse=false --echo=true --user admin --passwordfile=#{t.context.domain_password_file_location} #{secure ? '--secure ' : ''}--port 4848 --host 127.0.0.1 restart-domain --domaindir #{test_domains_dir} \"$@\" #{t.context.domain_name}
    CMD
  end
end
