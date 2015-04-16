require File.expand_path('../helper', __FILE__)

class TestBlah < Redfish::TestCase
  def test_properties_are_duplicated
    t = Redfish::Property.new
    t.context = Redfish::Context.new(Redfish::Executor.new,
                                     '/Users/peter/Applications/payara-4.1.151/',
                                     'domain1',
                                     4848,
                                     false,
                                     'admin',
                                     nil,
                                     :terse => false,
                                     :echo => true)

    t.key = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)
  end
end
