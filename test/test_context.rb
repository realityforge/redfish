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

    context = Redfish::Context.new(Redfish::Executor.new,
                                   install_dir,
                                   domain_name,
                                   domain_admin_port,
                                   domain_secure,
                                   domain_username,
                                   domain_password,
                                   :system_user => system_user,
                                   :system_group => system_group,
                                   :terse => true,
                                   :echo => true)

    assert_equal context.domain_name, domain_name
    assert_equal context.domain_admin_port, domain_admin_port
    assert_equal context.domain_secure, domain_secure
    assert_equal context.domain_username, domain_username
    assert_equal context.domain_password, domain_password

    assert_equal context.terse?, true
    assert_equal context.echo?, true
    assert_equal context.system_user, system_user
    assert_equal context.system_group, system_group

    assert !context.property_cache?
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

    context.cache_properties('domain.version' => '#badassfish-b187')
    assert_equal context.domain_version, {:variant => 'Payara', :version => '4.1.152'}
    context.remove_property_cache
    assert_equal context.domain_version('#badassfish-b187'), {:variant => 'Payara', :version => '4.1.152'}

    context.cache_properties('domain.version' => '270')
    assert_equal context.domain_version, {:variant => 'Payara', :version => '4.1.1.154'}
    context.remove_property_cache
    assert_equal context.domain_version('270'), {:variant => 'Payara', :version => '4.1.1.154'}

    context.cache_properties('domain.version' => 'other')
    begin
      context.domain_version
    rescue => e
      assert_equal e.message, 'Unknown domain.version other'
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
