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

class Redfish::TestDefinition < Redfish::TestCase

  def test_basic_workflow
    definition = Redfish::DomainDefinition.new('appserver')

    assert_equal definition.file_map, {}
    assert_equal definition.volume_map, {}

    assert_equal definition.glassfish_home_defined?, false
    assert_equal definition.domains_directory_defined?, false

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal definition.name, 'appserver'
    assert definition.data.is_a?(Reality::Mash)
    assert_equal definition.secure?, true
    assert_equal definition.complete?, true
    assert_equal definition.local?, true
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
    assert_equal definition.volume_requirements, {}

    assert_equal definition.glassfish_home_defined?, false
    assert_equal definition.domains_directory_defined?, false

    definition.secure = false
    definition.complete = false
    definition.local = false
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
    volume_dir = "#{temp_dir}/test_volume"
    definition.volume('Z', volume_dir)
    definition.version = '1.21'
    definition.ports << 8080
    definition.data['environment_vars']['A'] = '1'
    definition.data['volumes']['V'] = {}

    assert_equal definition.secure?, false
    assert_equal definition.complete?, false
    assert_equal definition.local?, false
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
    assert_equal definition.base_image_name, 'stocksoftware/redfish:latest'
    assert_equal definition.file_map, {'a' => '/tmp/a.txt'}
    assert_equal definition.volume_map, {'Z' => volume_dir}
    assert_equal definition.version, '1.21'
    assert_equal definition.ports, [8080]
    assert_equal definition.environment_vars, {'A' => '1'}
    assert_equal definition.volume_requirements, {'V' => {}}

    assert_equal definition.glassfish_home_defined?, true
    assert_equal definition.domains_directory_defined?, true

    definition.base_image_name = 'stocksoftware/redfish:jdk8'
    assert_equal definition.base_image_name, 'stocksoftware/redfish:jdk8'

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
    assert_equal context.volume_map, {'Z' => volume_dir}
  end

  def test_extends
    Redfish::Config.default_glassfish_home = 'Y'

    definition = Redfish.domain('appserver')

    # Set a collection of variables, some of which are inherited and some of which are not

    definition.admin_username = 'myadmin'
    definition.master_password = 'mypassword'
    definition.admin_port = 8081
    definition.secure = false
    definition.local = false
    definition.authbind_executable = '/usr/bin/authbind'
    definition.system_user = 'glassfish'
    definition.system_group = 'glassfish-group'
    definition.file('a', '/tmp/a.txt')
    volume_dir = "#{temp_dir}/test_volume"
    definition.volume('Z', volume_dir)
    definition.ports << 8080
    definition.data['environment_vars']['A'] = '1'
    definition.data['volumes']['V'] = {}

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
    assert definition.data.is_a?(Reality::Mash)
    assert_equal definition.resolved_data,
                 {
                   'a' => 1,
                   'b' => 'p',
                   'd' => 3,
                   'e' => 4,
                   'f' => 'r',
                   'environment_vars' => {'A' => '1'},
                   'volumes' => {'V' => {}}
                 }
    assert_equal definition.pre_artifacts.size, 1
    assert_equal definition.post_artifacts.size, 1
    assert_equal definition.secure?, false
    assert_equal definition.local?, false
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
    assert_equal definition.volume_map, {'Z' => volume_dir}
    assert_equal definition.ports, [8080]
    assert_equal definition.environment_vars, {'A' => '1'}
    assert_equal definition.volume_requirements, {'V' => {}}

    definition2 = Redfish.domain('appserver2', :extends => 'appserver')

    assert_equal definition2.key, 'appserver2'
    assert_equal definition2.name, 'appserver'
    assert definition2.data.is_a?(Reality::Mash)
    assert_equal definition2.secure?, definition.secure?
    assert_equal definition2.local?, true
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
    assert_equal definition2.volume_map, {'Z' => volume_dir}
    assert_equal definition2.ports, [8080]
    assert_equal definition2.environment_vars, {'A' => '1'}
    assert_equal definition2.volume_requirements, {'V' => {}}

    assert_equal definition2.resolved_data,
                 {
                   'a' => 1,
                   'b' => 'p',
                   'd' => 3,
                   'e' => 4,
                   'f' => 'r',
                   'environment_vars' => {'A' => '1'},
                   'volumes' => {'V' => {}}
                 }
    assert_equal definition2.pre_artifacts.size, 0
    assert_equal definition2.post_artifacts.size, 0

    pre_filename2 = "#{temp_dir}/pre_data2.json"
    post_filename2 = "#{temp_dir}/post_data2.json"

    File.open(pre_filename2, 'wb') { |f| f.write '{"a": 4}' }
    File.open(post_filename2, 'wb') { |f| f.write '{"e": 5}' }

    definition2.pre_artifacts << pre_filename2
    definition2.post_artifacts << post_filename2

    assert_equal definition2.resolved_data,
                 {
                   'a' => 4,
                   'b' => 'p',
                   'd' => 3,
                   'e' => 5,
                   'f' => 'r',
                   'environment_vars' => {'A' => '1'},
                   'volumes' => {'V' => {}}
                 }

    definition2.data['d'] = 'X'
    definition2.data['q'] = 'Y'

    assert_equal definition2.resolved_data,
                 {
                   'a' => 4,
                   'b' => 'p',
                   'd' => 'X',
                   'e' => 5,
                   'f' => 'r',
                   'q' => 'Y',
                   'environment_vars' => {'A' => '1'},
                   'volumes' => {'V' => {}}
                 }
  end

  def test_checkpoint_data
    Redfish::Config.default_glassfish_home = 'Y'

    domain = Redfish.domain('appserver')

    assert_equal domain.data, {}
    assert_equal domain.checkpointed_data, {}

    domain.data['a'] = 4
    domain.data['b'] = 'p'

    assert_equal domain.data, {'a' => 4, 'b' => 'p'}
    assert_equal domain.checkpointed_data, {}

    domain.checkpoint_data!

    assert_equal domain.data, {'a' => 4, 'b' => 'p'}
    assert_equal domain.checkpointed_data, {'a' => 4, 'b' => 'p'}

    domain.data['a'] = 5

    assert_equal domain.data, {'a' => 5, 'b' => 'p'}
    assert_equal domain.checkpointed_data, {'a' => 4, 'b' => 'p'}
  end

  def test_export_to_file
    definition = Redfish::DomainDefinition.new('appserver')

    filename = "#{temp_dir}/export1.json"
    definition.export_to_file(filename)
    assert File.exist?(filename)
    assert_equal JSON.load(File.new(filename)).to_h, {}

    definition.data['b']['c'] = 1
    definition.data['a'] = true
    definition.data['2'] = 1.0
    definition.data['1'] = false
    definition.data['4'] = nil
    definition.data['3'] = 'sdsada'

    filename = "#{temp_dir}/export2.json"
    definition.export_to_file(filename)
    assert File.exist?(filename)
    data2 = JSON.load(File.new(filename)).to_h
    assert_equal data2, {'1' => false, '2' => 1.0, '3' => 'sdsada', '4' => nil, 'a' => true, 'b' => {'c' => 1}}
    assert_equal data2.keys, %w(1 2 3 4 a b)

    filename = "#{temp_dir}/export3.json"
    definition.export_to_file(filename, :checkpointed_data => true)
    assert File.exist?(filename)
    data3 = JSON.load(File.new(filename)).to_h
    assert_equal data3, {}

    definition.checkpoint_data!
    definition.data['3'] = 'XXXXX'

    filename = "#{temp_dir}/export4.json"
    definition.export_to_file(filename, :checkpointed_data => true)
    assert File.exist?(filename)
    data4 = JSON.load(File.new(filename)).to_h
    assert_equal data4, {'1' => false, '2' => 1.0, '3' => 'sdsada', '4' => nil, 'a' => true, 'b' => {'c' => 1}}
    assert_equal data4.keys, %w(1 2 3 4 a b)
  end

  def test_export_to_file_and_expand
    Redfish::Config.default_glassfish_home = '/path/to/glassfish'

    definition = Redfish::DomainDefinition.new('appserver')

    filename2 = "#{temp_dir}/export1.json"
    definition.export_to_file(filename2, :expand => true)
    assert File.exist?(filename2)
    assert_equal JSON.load(File.new(filename2)).to_h, {'jms_resources' => {}, 'properties' => {}}

    definition.data['properties']['some.property'] = '{{domain_name}}'
    definition.data['jms_resources']['myapp/jms/MyQueue']['restype'] = 'javax.jms.Queue'
    definition.data['jms_resources']['myapp/jms/MyQueue']['properties']['name'] = 'MyQueue'

    filename2 = "#{temp_dir}/export2.json"
    definition.export_to_file(filename2, :expand => true)
    assert File.exist?(filename2)
    data2 = JSON.load(File.new(filename2)).to_h
    expected =
      {
        'jms_resources' =>
          {
            'myapp/jms/MyQueue' => {'properties' => {'name' => 'MyQueue'}, 'restype' => 'javax.jms.Queue'}
          },
        'properties' => {'some.property' => 'appserver'},
        'resource_adapters' =>
          {
            'jmsra' =>
              {
                'admin_objects' =>
                  {
                    'myapp/jms/MyQueue' => {'restype' => 'javax.jms.Queue', 'properties' => {'name' => 'MyQueue'}
                    }
                  }
              }
          }
      }
    assert_equal data2, expected
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

  def test_volume_map
    volume_dir = "#{temp_dir}/test_volume"
    volume_dir2 = "#{temp_dir}/test_volume"

    definition = Redfish::DomainDefinition.new('appserver', :volume_map => {'a' => volume_dir})

    assert_equal definition.volume_map, {'a' => volume_dir}

    definition.volume('b', volume_dir2)

    assert_equal definition.volume_map, {'a' => volume_dir, 'b' => volume_dir2}

    # Ensure it can not be changed directly

    definition.volume_map['c'] = '/filec.txt'

    assert_equal definition.volume_map, {'a' => volume_dir, 'b' => volume_dir2}

    e = assert_raises(RuntimeError) { definition.volume('a', volume_dir) }
    assert_equal e.message, "Volume with key 'a' is associated with directory '#{volume_dir}', can not associate with '#{volume_dir}'"
  end

  def test_labels
    definition = Redfish::DomainDefinition.new('appserver')

    definition.additional_labels['application'] = 'ember'

    Redfish::Config.default_glassfish_home = '/path/to/glassfish'
    labels = definition.labels
    assert_equal labels.size, 4
    assert_equal labels['org.realityforge.redfish.domain_name'], 'appserver'
    assert_equal labels['org.realityforge.redfish.domain_version'], ''
    assert_equal labels['org.realityforge.redfish.domain_hash'], definition.version_hash
    assert_equal labels['application'], 'ember'
  end

  def test_version_hash
    Redfish::Config.default_glassfish_home = '/path/to/glassfish'

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

    definition.data['environment_vars']['A'] = 'P'
    version_hash = check_version_hash(definition, true, version_hash)

    definition.data['volumes']['V'] = {}
    version_hash = check_version_hash(definition, true, version_hash)

    definition.file('b', '/tmp/b.txt')
    version_hash = check_version_hash(definition, true, version_hash)

    volume_dir = "#{temp_dir}/test_volume"
    definition.volume('A', volume_dir)
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

  def test_base_image_name_requires_dockerize
    assert_redfish_error('base_image_name invoked on domain appserver which should not be dockerized') do
      Redfish::DomainDefinition.new('appserver').base_image_name
    end
    assert_redfish_error('base_image_name= invoked on domain appserver which should not be dockerized') do
      Redfish::DomainDefinition.new('appserver').base_image_name = 'X'
    end
  end

  def test_image_name_requires_dockerize
    assert_redfish_error('image_name invoked on domain appserver which should not be dockerized') do
      Redfish::DomainDefinition.new('appserver').image_name
    end
  end

  def test_docker_build_command
    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true

    assert_equal domain.docker_build_command('/my/dir'), 'docker build --pull --rm=true -t appserver /my/dir'
    assert_equal domain.docker_build_command('/my/dir', :quiet => true), 'docker build --pull -q --rm=true -t appserver /my/dir'

    domain.version = 'X'
    assert_equal domain.docker_build_command('/my/dir', :quiet => true), 'docker build --pull -q --rm=true -t appserver:X /my/dir'
  end

  def test_docker_run_command
    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true

    assert_equal domain.docker_run_command, 'docker run -ti --rm -P --name appserver appserver'
    domain.docker_dns = '10.0.9.9'
    assert_equal domain.docker_run_command, 'docker run -ti --rm -P --dns=10.0.9.9 --name appserver appserver'
    domain.docker_run_args << '--env=A=a'
    domain.docker_run_args << '--env=B=b'
    assert_equal domain.docker_run_command, 'docker run -ti --rm -P --dns=10.0.9.9 --name appserver --env=A=a --env=B=b appserver'

    volume_dir = "#{temp_dir}/test_volume"
    volume_dir2 = "#{temp_dir}/test_volume2"
    domain.volume('A', volume_dir)
    domain.volume('B', volume_dir2)
    assert_equal domain.docker_run_command, "docker run -ti --rm -P --dns=10.0.9.9 --volume=#{volume_dir}:/srv/glassfish/volumes/A --volume=#{volume_dir2}:/srv/glassfish/volumes/B --name appserver --env=A=a --env=B=b appserver"

    domain.data['environment_vars']['C'] = '1'
    domain.data['environment_vars']['D'] = '2'
    assert_equal domain.docker_run_command, "docker run -ti --rm -P --dns=10.0.9.9 --env=\"C=1\" --env=\"D=2\" --volume=#{volume_dir}:/srv/glassfish/volumes/A --volume=#{volume_dir2}:/srv/glassfish/volumes/B --name appserver --env=A=a --env=B=b appserver"
  end

  def test_image_name
    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true

    assert_equal domain.image_name, 'appserver'

    domain.version = '1.0'

    assert_equal domain.image_name, 'appserver:1.0'
  end

  def test_setup_docker_dir
    Redfish::Config.default_glassfish_home = '/opt/glassfish'

    dir = "#{temp_dir}/docker"

    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true

    domain.setup_docker_dir(dir)

    assert_docker_directory('redfish')
    assert_docker_directory('redfish/lib')
    assert_docker_directory('redfish/lib/redfish')
    assert_docker_directory('redfish/lib/redfish_plus')
    assert_docker_file('redfish/lib/redfish.rb')
    assert_docker_file('redfish/lib/redfish_plus.rb')
    assert_docker_file('Dockerfile', <<CONTENT)
FROM stocksoftware/redfish:latest
USER root
COPY ./redfish /opt/redfish
RUN chmod -R a+r /opt/redfish && find /opt/redfish -type d -exec chmod a+x {} \\; && chmod a+x /opt/redfish/run
USER glassfish:glassfish
RUN mkdir -p /tmp/glassfish && \\
    export TMPDIR=/tmp/glassfish && \\
    java -jar ${JRUBY_JAR} /opt/redfish/domain.rb && \\
    java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/appserver/config/domain.xml && \\
    rm -rf /tmp/glassfish /srv/glassfish/.gfclient /tmp/hsperfdata_glassfish /srv/glassfish/domains/appserver/config/secure.marker

USER glassfish:glassfish
EXPOSE  4848
CMD ["/opt/redfish/run"]
WORKDIR /srv/glassfish/domains/appserver
LABEL org.realityforge.redfish.domain_name="appserver" \\
      org.realityforge.redfish.domain_version="" \\
      org.realityforge.redfish.domain_hash="#{domain.version_hash}"
CONTENT

    assert_docker_file('redfish/run', <<CONTENT)
#!/bin/bash

java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/appserver/config/domain.xml && \\
/srv/glassfish/domains/appserver/bin/asadmin_run
CONTENT
    assert_docker_file('redfish/domain.rb', <<CONTENT)
CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path("\#{CURRENT_DIR}/lib")
require 'redfish_plus'

domain = Redfish.domain('appserver') do |domain|
  domain.pre_artifacts << "\#{CURRENT_DIR}/domain.json"
end

Redfish::Driver.configure_domain(domain, :listeners => [Redfish::BasicListener.new])
CONTENT
    assert_docker_file('redfish/domain.json', JSON.pretty_generate({}))
  end

  def test_setup_docker_dir_with_different_image
    Redfish::Config.default_glassfish_home = '/opt/glassfish'

    dir = "#{temp_dir}/docker"

    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true
    domain.base_image_name = 'stocksoftware/redfish:jdk8'

    domain.setup_docker_dir(dir)
    assert_docker_file('Dockerfile', /^FROM stocksoftware\/redfish\:jdk8\n/)
  end

  def test_setup_docker_dir_with_files_volumes_and_env_vars
    Redfish::Config.default_glassfish_home = '/opt/glassfish'

    file1 = "#{temp_dir}/file1.json"
    file2 = "#{temp_dir}/file2.json"

    File.open(file1, 'wb') { |f| f.write '{"a": 1, "b": 2}' }
    File.open(file2, 'wb') { |f| f.write '{"c": 1, "d": 2}' }

    dir = "#{temp_dir}/docker"

    domain = Redfish::DomainDefinition.new('appserver')
    domain.dockerize = true

    domain.data['data'] = 'some data here'

    domain.data['environment_vars']['A'] = nil
    domain.data['environment_vars']['B'] = nil
    domain.data['environment_vars']['C'] = '1'

    domain.data['volumes']['V'] = {}

    domain.file('a', file1)
    domain.file('b', file2)

    volume_dir = "#{temp_dir}/test_volume"
    domain.volume('A', volume_dir)

    volume_dir = "#{temp_dir}/test_volume2"
    domain.volume('B', volume_dir)

    domain.setup_docker_dir(dir)

    assert_docker_directory('redfish')
    assert_docker_directory('redfish/lib')
    assert_docker_directory('redfish/lib/redfish')
    assert_docker_directory('redfish/lib/redfish_plus')
    assert_docker_file('redfish/lib/redfish.rb')
    assert_docker_file('redfish/lib/redfish_plus.rb')
    assert_docker_file('Dockerfile', <<CONTENT)
FROM stocksoftware/redfish:latest
USER root
COPY ./redfish /opt/redfish
RUN chmod -R a+r /opt/redfish && find /opt/redfish -type d -exec chmod a+x {} \\; && chmod a+x /opt/redfish/run
USER glassfish:glassfish
RUN mkdir -p /tmp/glassfish /srv/glassfish/volumes/A /srv/glassfish/volumes/B && \\
    export TMPDIR=/tmp/glassfish && \\
    java -jar ${JRUBY_JAR} /opt/redfish/domain.rb && \\
    java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/appserver/config/domain.xml -sA=@@A@@ -sB=@@B@@ -sC=@@C@@ && \\
    rm -rf /tmp/glassfish /srv/glassfish/.gfclient /tmp/hsperfdata_glassfish /srv/glassfish/domains/appserver/config/secure.marker

USER glassfish:glassfish
EXPOSE  4848
CMD ["/opt/redfish/run"]
WORKDIR /srv/glassfish/domains/appserver
VOLUME /srv/glassfish/volumes/A /srv/glassfish/volumes/B
LABEL org.realityforge.redfish.domain_name="appserver" \\
      org.realityforge.redfish.domain_version="" \\
      org.realityforge.redfish.domain_hash="#{domain.version_hash}"
CONTENT

    assert_docker_file('redfish/run', <<CONTENT)
#!/bin/bash

if [ "${A:-}" = '' ]; then
  echo "Failed to supply environment data for A"
  exit 1
fi
if [ "${B:-}" = '' ]; then
  echo "Failed to supply environment data for B"
  exit 1
fi
if [ "${C:-1}" = '' ]; then
  echo "Failed to supply environment data for C"
  exit 1
fi
java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/appserver/config/domain.xml -sA=${A:-} -sB=${B:-} -sC=${C:-1} && \\
/srv/glassfish/domains/appserver/bin/asadmin_run
CONTENT
    assert_docker_file('redfish/domain.rb', <<CONTENT)
CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path("\#{CURRENT_DIR}/lib")
require 'redfish_plus'

domain = Redfish.domain('appserver') do |domain|
  domain.pre_artifacts << "\#{CURRENT_DIR}/domain.json"
  domain.file('a', '/opt/redfish/files/a/file1.json')
  domain.file('b', '/opt/redfish/files/b/file2.json')
  domain.volume('A', '/srv/glassfish/volumes/A')
  domain.volume('B', '/srv/glassfish/volumes/B')
end

Redfish::Driver.configure_domain(domain, :listeners => [Redfish::BasicListener.new])
CONTENT
    expected =
      {
        'data' => 'some data here',
        'environment_vars' => {'A' => nil, 'B' => nil, 'C' => '1'},
        'volumes' => {'V' => {}}
      }
    assert_docker_file('redfish/domain.json', JSON.pretty_generate(expected))
  end

  def assert_docker_file(filename, content = nil)
    path = "#{temp_dir}/docker/#{filename}"
    assert_file(path)
    if content
      data = IO.read(path)
      if content.is_a?(Regexp)
        assert_match content, data
      else
        assert_equal content, data
      end
    end
  end

  def assert_docker_directory(filename)
    assert_directory("#{temp_dir}/docker/#{filename}")
  end

  def assert_directory(filename)
    assert File.directory?(filename)
  end

  def assert_file(filename)
    assert File.file?(filename)
  end
end
