module Redfish
  module Tasks
    class IiopListener < BaseResourceTask

      attribute :name, :kind_of => String, :required => true

      # Either the IP address or the hostname (resolvable by DNS).
      attribute :address, :kind_of => String, :default => '0.0.0.0'
      # The IIOP port number.
      attribute :port, :kind_of => Integer, :default => 1072
      # If set to true, the IIOP listener runs SSL. You can turn SSL2 or SSL3 ON or OFF and set ciphers using an SSL element. The security setting globally enables or disables SSL by making certificates available to the server instance.
      attribute :securityenabled, :equal_to => [true, false, 'true', 'false'], :default => false
      # If set to true, the IIOP listener is enabled at runtime.
      attribute :enabled, :equal_to => [true, false, 'true', 'false'], :default => true
      # Optional attribute name/value pairs for configuring the IIOP listener.
      attribute :properties, :kind_of => Hash, :default => {}

      action :create do
        create(property_prefix)
      end

      action :destroy do
        destroy(property_prefix)
      end

      def properties_to_record_in_create
        {}
      end

      def properties_to_set_in_create
        property_map = {}

        collect_property_sets(property_prefix, property_map)

        property_map['address'] = self.address
        property_map['enabled'] = self.enabled.to_s
        property_map['port'] = self.port.to_s
        property_map['security-enabled'] = self.securityenabled.to_s

        property_map
      end

      def do_create
        args = []

        args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
        args << '--listeneraddress' << self.address.to_s
        args << '--iiopport' << self.port.to_s
        args << '--securityenabled' << self.securityenabled.to_s
        args << '--enabled' << self.enabled.to_s
        args << self.name.to_s

        context.exec('create-iiop-listener', args)
      end

      def do_destroy
        context.exec('delete-iiop-listener', [self.name])
      end

      def present?
        (context.exec('list-iiop-listeners', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end

      def property_prefix
        "configs.config.server-config.iiop-service.iiop-listener.#{self.name}."
      end
    end
  end
end
