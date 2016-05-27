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

require File.expand_path('../helper', __FILE__)

class Redfish::TestDefinition < Redfish::TestCase

  def test_basic_workflow
    definition = Redfish::DomainDefinition.new('appserver')

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal definition.name, 'appserver'
    assert definition.data.is_a?(Redfish::Mash)
    assert_equal definition.secure?, true
    assert_equal definition.admin_port, 4848
    assert_equal definition.admin_username, 'admin'
    assert_equal definition.master_password, nil
    assert_equal definition.admin_password.size, 10
    assert_equal definition.glassfish_home, 'Y'
    assert_equal definition.domains_directory, 'Y/glassfish/domains'
    assert_equal definition.authbind_executable, nil
    assert_equal definition.system_user, nil
    assert_equal definition.system_group, nil
    assert_equal definition.terse?, false
    assert_equal definition.echo?, false
    assert_equal definition.enable_rake_integration?, true
    assert_equal definition.packaged?, false

    definition.secure = false
    definition.admin_port = 8080
    definition.admin_username = 'bob'
    definition.admin_password = 'secret'
    definition.glassfish_home = '/usr/local/glassfish'
    definition.domains_directory = '/srv/glassfish/appserver'
    definition.authbind_executable = '/usr/bin/authbind'
    definition.system_user = 'glassfish'
    definition.system_group = 'glassfish-group'
    definition.terse = true
    definition.echo = true
    definition.rake_integration = false
    definition.packaged = true

    assert_equal definition.secure?, false
    assert_equal definition.admin_port, 8080
    assert_equal definition.admin_username, 'bob'
    assert_equal definition.admin_password, 'secret'
    assert_equal definition.glassfish_home, '/usr/local/glassfish'
    assert_equal definition.domains_directory, '/srv/glassfish/appserver'
    assert_equal definition.authbind_executable, '/usr/bin/authbind'
    assert_equal definition.system_user, 'glassfish'
    assert_equal definition.system_group, 'glassfish-group'
    assert_equal definition.terse?, true
    assert_equal definition.echo?, true
    assert_equal definition.enable_rake_integration?, false
    assert_equal definition.packaged?, true

    context = definition.to_task_context

    assert_equal context.domain_name, 'appserver'
    assert_equal context.domain_admin_port, 8080
    assert_equal context.domain_secure, false
    assert_equal context.domain_username, 'bob'
    assert_equal context.domain_password, 'secret'
    assert_equal context.domain_master_password, 'secret'
    assert_equal context.authbind_executable, '/usr/bin/authbind'
    assert_equal context.system_user, 'glassfish'
    assert_equal context.system_group, 'glassfish-group'
    assert_equal context.terse?, true
    assert_equal context.echo?, true
  end

  def test_export_to_file
    definition = Redfish::DomainDefinition.new('appserver')

    filename2 = "#{temp_dir}/export1.json"
    definition.export_to_file(filename2)
    assert File.exist?(filename2)
    assert_equal JSON.load(File.new(filename2)).to_h, {}

    definition.data['b']['c'] = 1
    definition.data['a'] = true
    definition.data['2'] = 1.0
    definition.data['1'] = false
    definition.data['4'] = nil
    definition.data['3'] = 'sdsada'

    filename2 = "#{temp_dir}/export2.json"
    definition.export_to_file(filename2)
    assert File.exist?(filename2)
    data2 = JSON.load(File.new(filename2)).to_h
    assert_equal data2, {'1' => false, '2' => 1.0, '3' => 'sdsada', '4' => nil, 'a' => true, 'b' => {'c' => 1}}
    assert_equal data2.keys, %w(1 2 3 4 a b)
  end

  def test_task_prefix
    definition = Redfish::DomainDefinition.new('appserver')

    assert_equal definition.task_prefix, 'redfish:domain:appserver'

    Redfish::Config.default_domain_key = 'appserver'

    assert_equal definition.task_prefix, 'redfish:domain'
  end

  def test_pre_post_artifacts
    pre_filename = "#{temp_dir}/pre_data.json"
    post_filename = "#{temp_dir}/post_data.json"

    File.open(pre_filename, 'wb') { |f| f.write '{"a": 1, "b": 2}' }
    File.open(post_filename, 'wb') { |f| f.write '{"d": 3, "e": 4}' }

    definition = Redfish::DomainDefinition.new('appserver')
    definition.pre_artifacts << pre_filename
    definition.post_artifacts << post_filename

    definition.data['b'] = 'p'
    definition.data['d'] = 'q'
    definition.data['f'] = 'r'

    assert_equal definition.resolved_data, {'a' => 1, 'b' => 'p', 'd' => 3, 'e' => 4, 'f' => 'r'}
  end
end
