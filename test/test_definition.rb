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

    assert_equal definition.file_map, {}

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal definition.name, 'appserver'
    assert definition.data.is_a?(Redfish::Mash)
    assert_equal definition.secure?, true
    assert_equal definition.complete?, true
    assert_equal definition.package?, true
    assert_equal definition.admin_port, 4848
    assert_equal definition.admin_username, 'admin'
    assert_equal definition.master_password, nil
    assert_equal definition.admin_password.size, 10
    assert_equal definition.admin_password_random?, true
    assert_equal definition.glassfish_home, 'Y'
    assert_equal definition.domains_directory, 'Y/glassfish/domains'
    assert_equal definition.authbind_executable, nil
    assert_equal definition.system_user, nil
    assert_equal definition.system_group, nil
    assert_equal definition.terse?, false
    assert_equal definition.echo?, false
    assert_equal definition.enable_rake_integration?, true
    assert_equal definition.packaged?, false
    assert_equal definition.dockerize?, false
    assert_equal definition.extends, nil
    assert_equal definition.version, nil
    assert_equal definition.ports, []
    assert_equal definition.environment_vars, {}

    definition.secure = false
    definition.complete = false
    definition.package = false
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
    definition.dockerize = true
    definition.file('a', '/tmp/a.txt')
    definition.version = '1.21'
    definition.ports << 8080
    definition.environment_vars['A'] = '1'

    assert_equal definition.secure?, false
    assert_equal definition.complete?, false
    assert_equal definition.package?, false
    assert_equal definition.admin_port, 8080
    assert_equal definition.admin_username, 'bob'
    assert_equal definition.admin_password, 'secret'
    assert_equal definition.admin_password_random?, false
    assert_equal definition.glassfish_home, '/usr/local/glassfish'
    assert_equal definition.domains_directory, '/srv/glassfish/appserver'
    assert_equal definition.authbind_executable, '/usr/bin/authbind'
    assert_equal definition.system_user, 'glassfish'
    assert_equal definition.system_group, 'glassfish-group'
    assert_equal definition.terse?, true
    assert_equal definition.echo?, true
    assert_equal definition.enable_rake_integration?, false
    assert_equal definition.packaged?, true
    assert_equal definition.dockerize?, true
    assert_equal definition.file_map, {'a' => '/tmp/a.txt'}
    assert_equal definition.version, '1.21'
    assert_equal definition.ports, [8080]
    assert_equal definition.environment_vars, {'A' => '1'}

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
    assert_equal context.file_map, {'a' => '/tmp/a.txt'}
  end

  def test_extends
    Redfish::Config.default_glassfish_home = 'Y'

    definition = Redfish.domain('appserver')

    # Set a collection of variables, some of which are inherited and some of which are not

    definition.admin_username = 'myadmin'
    definition.master_password = 'mypassword'
    definition.admin_port = 8081
    definition.secure = false
    definition.authbind_executable = '/usr/bin/authbind'
    definition.system_user = 'glassfish'
    definition.system_group = 'glassfish-group'
    definition.file('a', '/tmp/a.txt')
    definition.ports << 8080
    definition.environment_vars['A'] = '1'

    # Deliberately do not copy @packaged, @package, @complete, @pre_artifacts, @post_artifacts, @rake_integration
    definition.complete = false
    definition.rake_integration = false
    definition.packaged = true
    definition.package = false

    pre_filename = "#{temp_dir}/pre_data.json"
    post_filename = "#{temp_dir}/post_data.json"

    File.open(pre_filename, 'wb') { |f| f.write '{"a": 1, "b": 2}' }
    File.open(post_filename, 'wb') { |f| f.write '{"d": 3, "e": 4}' }

    definition.pre_artifacts << pre_filename
    definition.post_artifacts << post_filename

    # Data accessed as resolved data
    definition.data['b'] = 'p'
    definition.data['d'] = 'q'
    definition.data['f'] = 'r'

    assert_equal definition.key, 'appserver'
    assert_equal definition.name, 'appserver'
    assert definition.data.is_a?(Redfish::Mash)
    assert_equal definition.resolved_data, {'a' => 1, 'b' => 'p', 'd' => 3, 'e' => 4, 'f' => 'r'}
    assert_equal definition.pre_artifacts.size, 1
    assert_equal definition.post_artifacts.size, 1
    assert_equal definition.secure?, false
    assert_equal definition.complete?, false
    assert_equal definition.package?, false
    assert_equal definition.admin_port, 8081
    assert_equal definition.admin_username, 'myadmin'
    assert_equal definition.admin_password_random?, true
    assert_equal definition.master_password, 'mypassword'
    assert_equal definition.admin_password.size, 10
    assert_equal definition.glassfish_home, 'Y'
    assert_equal definition.domains_directory, 'Y/glassfish/domains'
    assert_equal definition.authbind_executable, '/usr/bin/authbind'
    assert_equal definition.system_user, 'glassfish'
    assert_equal definition.system_group, 'glassfish-group'
    assert_equal definition.terse?, false
    assert_equal definition.echo?, false
    assert_equal definition.enable_rake_integration?, false
    assert_equal definition.packaged?, true
    assert_equal definition.extends, nil
    assert_equal definition.file_map, {'a' => '/tmp/a.txt'}
    assert_equal definition.ports, [8080]
    assert_equal definition.environment_vars, {'A' => '1'}

    definition2 = Redfish.domain('appserver2', :extends => 'appserver')

    assert_equal definition2.key, 'appserver2'
    assert_equal definition2.name, 'appserver'
    assert definition2.data.is_a?(Redfish::Mash)
    assert_equal definition2.secure?, definition.secure?
    assert_equal definition2.complete?, true
    assert_equal definition2.package?, true
    assert_equal definition2.admin_port, definition.admin_port
    assert_equal definition2.admin_username, definition.admin_username
    assert_equal definition2.admin_password_random?, true
    assert_equal definition2.master_password, definition.master_password
    assert_equal definition2.admin_password, definition.admin_password
    assert_equal definition2.glassfish_home, definition.glassfish_home
    assert_equal definition2.domains_directory, definition.domains_directory
    assert_equal definition2.authbind_executable, definition.authbind_executable
    assert_equal definition2.system_user, definition.system_user
    assert_equal definition2.system_group, definition.system_group
    assert_equal definition2.terse?, definition.terse?
    assert_equal definition2.echo?, definition.echo?
    assert_equal definition2.enable_rake_integration?, true
    assert_equal definition2.packaged?, false
    assert_equal definition2.extends, 'appserver'
    assert_equal definition2.file_map, {'a' => '/tmp/a.txt'}
    assert_equal definition2.ports, [8080]
    assert_equal definition2.environment_vars, {'A' => '1'}

    assert_equal definition2.resolved_data, {'a' => 1, 'b' => 'p', 'd' => 3, 'e' => 4, 'f' => 'r'}
    assert_equal definition2.pre_artifacts.size, 0
    assert_equal definition2.post_artifacts.size, 0

    pre_filename2 = "#{temp_dir}/pre_data2.json"
    post_filename2 = "#{temp_dir}/post_data2.json"

    File.open(pre_filename2, 'wb') { |f| f.write '{"a": 4}' }
    File.open(post_filename2, 'wb') { |f| f.write '{"e": 5}' }

    definition2.pre_artifacts << pre_filename2
    definition2.post_artifacts << post_filename2

    assert_equal definition2.resolved_data, {'a' => 4, 'b' => 'p', 'd' => 3, 'e' => 5, 'f' => 'r'}

    definition2.data['d'] = 'X'
    definition2.data['q'] = 'Y'

    assert_equal definition2.resolved_data, {'a' => 4, 'b' => 'p', 'd' => 'X', 'e' => 5, 'f' => 'r', 'q' => 'Y'}
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

  def test_file_map
    definition = Redfish::DomainDefinition.new('appserver', :file_map => {'a' => '/tmp/a.txt'})

    assert_equal definition.file_map, {'a' => '/tmp/a.txt'}

    definition.file('b', '/tmp/b.txt')

    assert_equal definition.file_map, {'a' => '/tmp/a.txt', 'b' => '/tmp/b.txt'}

    # Ensure it can not be changed directly

    definition.file_map['c'] = '/filec.txt'

    assert_equal definition.file_map, {'a' => '/tmp/a.txt', 'b' => '/tmp/b.txt'}

    e = assert_raises(RuntimeError) { definition.file('a', '/tmp/other.txt') }
    assert_equal e.message, "File with key 'a' is associated with local file '/tmp/a.txt', can not associate with '/tmp/other.txt'"
  end

  def test_labels
    definition = Redfish::DomainDefinition.new('appserver')

    definition.additional_labels['application'] = 'ember'

    labels = definition.labels
    assert_equal labels.size, 4
    assert_equal labels['domain_name'], 'appserver'
    assert_equal labels['domain_version'], ''
    assert_equal labels['domain_hash'], definition.version_hash
    assert_equal labels['application'], 'ember'
  end

  def test_version_hash
    pre_filename = "#{temp_dir}/pre_data.json"
    post_filename = "#{temp_dir}/post_data.json"

    File.open(pre_filename, 'wb') { |f| f.write '{"a": 1, "b": 2}' }
    File.open(post_filename, 'wb') { |f| f.write '{"d": 3, "e": 4}' }

    definition = Redfish::DomainDefinition.new('appserver')

    version_hash = check_version_hash(definition, true, '')

    definition.data['hello'] = 'world'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.version = '1.354'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.pre_artifacts << pre_filename
    version_hash = check_version_hash(definition, true, version_hash)

    definition.post_artifacts << post_filename
    version_hash = check_version_hash(definition, true, version_hash)

    definition.ports = [8080]
    version_hash = check_version_hash(definition, true, version_hash)

    definition.secure = false
    version_hash = check_version_hash(definition, true, version_hash)

    definition.admin_port = 8085
    version_hash = check_version_hash(definition, true, version_hash)

    definition.admin_username = 'bob'
    version_hash = check_version_hash(definition, true, version_hash)

    # This clears the admin_password_random? flag thus forcing a hash change
    definition.admin_password = definition.admin_password
    version_hash = check_version_hash(definition, true, version_hash)

    definition.domains_directory = '/tmp'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.glassfish_home = '/tmp'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.authbind_executable = '/bin/authbind'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.system_user = 'gf'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.system_group = 'gf-admins'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.environment_vars['A'] = 'P'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.file('b', '/tmp/b.txt')
    version_hash = check_version_hash(definition, true, version_hash)

    definition.package = false
    version_hash = check_version_hash(definition, false, version_hash)

    definition.package = true
    version_hash = check_version_hash(definition, false, version_hash)

    definition.rake_integration = false
    version_hash = check_version_hash(definition, false, version_hash)

    definition.rake_integration = true
    version_hash = check_version_hash(definition, false, version_hash)

    definition.complete = false
    version_hash = check_version_hash(definition, false, version_hash)

    definition.complete = true
    version_hash = check_version_hash(definition, false, version_hash)

    definition.echo = false
    version_hash = check_version_hash(definition, false, version_hash)

    definition.echo = true
    version_hash = check_version_hash(definition, false, version_hash)

    definition.terse = false
    version_hash = check_version_hash(definition, false, version_hash)

    definition.terse = true
    check_version_hash(definition, false, version_hash)
  end

  def check_version_hash(definition, expect_change, last_version_hash)
    version_hash = definition.version_hash
    version_hash2 = definition.version_hash
    if version_hash != version_hash2
      fail('Version_has changed without changing any data')
    end
    if (last_version_hash == version_hash) && expect_change
      fail('Expected version_hash change but was none')
    end
    if (last_version_hash != version_hash) && !expect_change
      fail('Did not expect version_hash change but was one')
    end
    version_hash
  end
end
