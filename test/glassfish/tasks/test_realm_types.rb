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

class Redfish::Tasks::Glassfish::TestRealmTypes < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_set_when_changing
    executor = Redfish::Executor.new
    t = new_task(executor)

    filename = "#{t.context.domain_directory}/config/login.conf"

    FileUtils.mkdir_p File.dirname(filename)
    FileUtils.touch filename

    t.context.cache_properties('domain.version' => DOMAIN_VERSION)

    assert !t.context.restart_required?

    t.default_realm_types = false
    t.realm_types = {'fileRealm' => 'com.sun.enterprise.security.auth.login.FileLoginModule'}
    t.perform_action(:set)

    assert t.context.restart_required?

    content = IO.read(filename)

    assert_equal content, "fileRealm {\n    com.sun.enterprise.security.auth.login.FileLoginModule required ;\n};\n"

    assert_file_mode(filename, '600')

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_changing_set_user
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor, :system_user => 'bob', :system_group => 'bobgrp'))

    filename = "#{t.context.domain_directory}/config/login.conf"

    FileUtils.mkdir_p File.dirname(filename)
    FileUtils.touch filename

    t.context.cache_properties('domain.version' => DOMAIN_VERSION)

    FileUtils.expects(:chown).with(equals('bob'), equals('bobgrp'), equals(filename)).returns('')

    assert !t.context.restart_required?

    t.default_realm_types = false
    t.realm_types = {'fileRealm' => 'com.sun.enterprise.security.auth.login.FileLoginModule'}
    t.perform_action(:set)

    assert t.context.restart_required?

    assert_equal IO.read(filename), "fileRealm {\n    com.sun.enterprise.security.auth.login.FileLoginModule required ;\n};\n"

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_changing_include_default
    executor = Redfish::Executor.new
    t = new_task(executor)

    filename = "#{t.context.domain_directory}/config/login.conf"

    FileUtils.mkdir_p File.dirname(filename)
    FileUtils.touch filename

    t.context.cache_properties('domain.version' => DOMAIN_VERSION)

    assert !t.context.restart_required?

    t.default_realm_types = true
    t.realm_types = {}
    t.perform_action(:set)

    assert t.context.restart_required?

    assert_equal IO.read(filename), "fileRealm {\n    com.sun.enterprise.security.auth.login.FileLoginModule required ;\n};\njdbcDigestRealm {\n    com.sun.enterprise.security.ee.auth.login.JDBCDigestLoginModule required ;\n};\njdbcRealm {\n    com.sun.enterprise.security.ee.auth.login.JDBCLoginModule required ;\n};\nldapRealm {\n    com.sun.enterprise.security.auth.login.LDAPLoginModule required ;\n};\npamRealm {\n    com.sun.enterprise.security.ee.auth.login.PamLoginModule required ;\n};\nsolarisRealm {\n    com.sun.enterprise.security.auth.login.SolarisLoginModule required ;\n};\n"

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_not_changing
    executor = Redfish::Executor.new
    t = new_task_with_context(create_simple_context(executor))

    filename = "#{t.context.domain_directory}/config/login.conf"

    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, 'wb') do |f|
      f.write "fileRealm {\n    com.sun.enterprise.security.auth.login.FileLoginModule required ;\n};\n"
    end

    t.context.cache_properties('domain.version' => DOMAIN_VERSION)

    assert !t.context.restart_required?

    t.default_realm_types = false
    t.realm_types = {'fileRealm' => 'com.sun.enterprise.security.auth.login.FileLoginModule'}
    t.perform_action(:set)

    assert !t.context.restart_required?

    assert_equal IO.read(filename), "fileRealm {\n    com.sun.enterprise.security.auth.login.FileLoginModule required ;\n};\n"

    ensure_task_not_updated_by_last_action(t)
  end

  def test_interpret_set
    data = {'realm_types' => {'managed' => true,
                              'default_realm_types' => false,
                              'modules' => {'fileRealm' => 'com.sun.enterprise.security.auth.login.FileLoginModule'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    filename = "#{context.domain_directory}/config/login.conf"

    FileUtils.mkdir_p File.dirname(filename)
    FileUtils.touch filename

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).
      with(equals(context),
           equals('list-domains'),
           equals(%W(--domaindir #{test_domains_dir})),
           equals({:terse => true, :echo => false})).
      returns("domain1\n")

    executor.expects(:exec).with(equals(context),
                                 equals('restart-domain'),
                                 equals(%W(--force=true --kill=false --domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('start-domain'),
                                 equals(%W(--domaindir #{test_domains_dir} domain1)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('_get-restart-required'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("false\n").
      at_least(DOMAIN_RESTART_IF_REQUIRED_ACTIONS - DOMAIN_CONTEXT_ONLY_RESTART_IF_REQUIRED_ACTIONS)


    perform_interpret(context,
                      data,
                      true,
                      :set,
                      # We create the directory by touching file so create will not occur
                      :exclude_domain_create => true,
                      # domain start+ensure_active+restart-domain
                      :additional_task_count => 3,
                      :additional_unchanged_task_count => DOMAIN_RESTART_IF_REQUIRED_ACTIONS)
  end
end
