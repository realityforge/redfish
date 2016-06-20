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

class Redfish::TestContext < Redfish::TestCase

  def test_basic_workflow
    install_dir = '/opt/glassfish'
    domain_name = 'appserver'
    domain_admin_port = 4848
    domain_secure = true
    domain_username = 'admin'
    domain_password = 'mypassword'
    system_user = 'glassfish'
    system_group = 'glassfish_group'
    file_map =
      {
        'a' => '/tmp/a',
        'b' => '/tmp/b',
        'c' => '/tmp/c',
      }

    context = Redfish::Context.new(Redfish::Executor.new,
                                   install_dir,
                                   domain_name,
                                   domain_admin_port,
                                   domain_secure,
                                   domain_username,
                                   domain_password,
                                   :system_user => system_user,
                                   :system_group => system_group,
                                   :file_map => file_map,
                                   :terse => true,
                                   :echo => true)

    assert_equal context.domain_name, domain_name
    assert_equal context.domain_admin_port, domain_admin_port
    assert_equal context.domain_secure, domain_secure
    assert_equal context.domain_username, domain_username
    assert_equal context.domain_password, domain_password
    assert_equal context.domain_master_password, domain_password

    assert_equal context.terse?, true
    assert_equal context.echo?, true
    assert_equal context.system_user, system_user
    assert_equal context.system_group, system_group
    assert_equal context.file_map, file_map

    assert !context.property_cache?
  end

  def test_file_map
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil)

    assert_equal context.file_map, {}

    context.file('a', '/tmp/a.txt')

    assert_equal context.file_map, {'a' => '/tmp/a.txt'}

    context.file('b', '/tmp/b.txt')

    assert_equal context.file_map, {'a' => '/tmp/a.txt', 'b' => '/tmp/b.txt'}

    # Ensure it can not be changed directly

    context.file_map['c'] = '/filec.txt'

    assert_equal context.file_map, {'a' => '/tmp/a.txt', 'b' => '/tmp/b.txt'}

    e = assert_raises(RuntimeError) { context.file('a', '/tmp/other.txt') }
    assert_equal e.message, "File with key 'a' is associated with local file '/tmp/a.txt', can not associate with '/tmp/other.txt'"
  end

  def test_volume_map
    volume_dir = "#{temp_dir}/test_volume"
    FileUtils.mkdir_p volume_dir

    volume_dir2 = "#{temp_dir}/test_volume"
    FileUtils.mkdir_p volume_dir2

    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil)

    assert_equal context.file_map, {}

    context.volume('a', volume_dir)

    assert_equal context.volume_map, {'a' => volume_dir}

    context.volume('b', volume_dir2)

    assert_equal context.volume_map, {'a' => volume_dir, 'b' => volume_dir2}

    # Ensure it can not be changed directly

    context.volume_map['c'] = '/filec.txt'

    assert_equal context.volume_map, {'a' => volume_dir, 'b' => volume_dir2}

    e = assert_raises(RuntimeError) { context.volume('a', volume_dir) }
    assert_equal e.message, "Volume with key 'a' is associated with directory '#{volume_dir}', can not associate with '#{volume_dir}'"
  end

  def test_domain_master_password_can_be_set
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   'mypassword',
                                   :domain_master_password => 'X')

    assert_equal context.domain_master_password, 'X'
  end

  def test_domain_master_password_has_reasonable_default_when_password_null
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil)

    assert !context.domain_master_password.nil?
    assert_equal context.domain_master_password.size, 10
  end

  def test_dirs_cleaned_of_trailing_slash
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish/',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil,
                                   :domains_directory => '/opt/glassfish/domains/')

    assert_equal context.install_dir, '/opt/glassfish'
    assert_equal context.domains_directory, '/opt/glassfish/domains'
  end

  def test_restart_required
    context = create_simple_context

    assert_equal context.restart_required?, false
    context.require_restart!
    assert_equal context.restart_required?, true
    context.domain_restarted!
    assert_equal context.restart_required?, false
  end

  def test_domain_started
    context = create_simple_context

    assert_equal context.domain_started?, false
    context.domain_started!
    assert_equal context.domain_started?, true
  end

  def test_domain_dir_when_domains_directory_specified
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish/',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil,
                                   :domains_directory => '/srv/glassfish/domains/')

    assert_equal context.domain_directory, '/srv/glassfish/domains/appserver'
  end

  def test_domain_dir_when_domains_directory_not_specified
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish/',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil)

    assert_equal context.domain_directory, '/opt/glassfish/glassfish/domains/appserver'
  end

  def test_domain_password_file_only_non_nil_if_present
    context = Redfish::Context.new(Redfish::Executor.new,
                                   '/opt/glassfish/',
                                   'appserver',
                                   4848,
                                   true,
                                   'admin',
                                   nil,
                                   :domains_directory => test_domains_dir)

    assert_equal context.domain_password_file, nil
    FileUtils.mkdir_p File.dirname(context.domain_password_file_location)
    FileUtils.touch context.domain_password_file_location
    assert_equal context.domain_password_file, context.domain_password_file_location
  end

  def test_domain_version
    context = Redfish::Context.new(Redfish::Executor.new, '/opt/glassfish', 'appserver', 4848, true, 'admin', nil)

    context.cache_properties('domain.version' => '270')
    assert_equal context.domain_version.payara?, true
    assert_equal context.domain_version.version, '4.1.1.154'
    context.remove_property_cache

    assert_equal context.domain_version('270').payara?, true
    assert_equal context.domain_version('270').version, '4.1.1.154'

    context.cache_properties('domain.version' => 'other')
    begin
      context.domain_version
    rescue => e
      assert_equal e.message, "No glassfish version registered with the version id 'other'"
    end
  end

  def test_property_caching
    context = Redfish::Context.new(Redfish::Executor.new, '/opt/glassfish', 'appserver', 4848, true, 'admin', nil)

    assert !context.property_cache?
    context.cache_properties('a' => '1', 'b' => '2')
    assert context.property_cache?
    assert_equal context.property_cache['a'], '1'
    assert_equal context.property_cache['b'], '2'

    error = false
    begin
      context.cache_properties('a' => '1', 'b' => '2')
    rescue
      error = true
    end
    fail('Expected to fail to re-cache properties') unless error

    context.remove_property_cache

    assert !context.property_cache?

    error = false
    begin
      context.remove_property_cache
    rescue
      error = true
    end
    fail('Expected to fail to remove property cache') unless error
  end
end
