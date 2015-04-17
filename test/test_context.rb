require File.expand_path('../helper', __FILE__)

class TestContext < Redfish::TestCase

  def test_basic_workflow
    install_dir = '/opt/glassfish'
    domain_name = 'appserver'
    domain_admin_port = 4848
    domain_secure = true
    domain_username = 'admin'
    domain_password_file = '/etc/glassfish/password'
    system_user = 'glassfish'
    system_group = 'glassfish_group'

    context = Redfish::Context.new(Redfish::Executor.new,
                                   install_dir,
                                   domain_name,
                                   domain_admin_port,
                                   domain_secure,
                                   domain_username,
                                   domain_password_file,
                                   :system_user => system_user,
                                   :system_group => system_group,
                                   :terse => true,
                                   :echo => true)

    assert_equal context.domain_name, domain_name
    assert_equal context.domain_admin_port, domain_admin_port
    assert_equal context.domain_secure, domain_secure
    assert_equal context.domain_username, domain_username
    assert_equal context.domain_password_file, domain_password_file

    assert_equal context.terse?, true
    assert_equal context.echo?, true
    assert_equal context.system_user, system_user
    assert_equal context.system_group, system_group

    assert !context.property_cache?
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
