module Redfish
  module Tasks
    class JavamailResource < BaseResourceTask

      attribute :name, :kind_of => String, :required => true
      attribute :host, :kind_of => String, :required => true
      attribute :user, :kind_of => String, :required => true
      attribute :from, :kind_of => String, :required => true
      attribute :store_protocol, :kind_of => String, :required => nil
      attribute :store_protocol_class, :kind_of => String, :required => nil
      attribute :transport_protocol, :kind_of => String, :required => nil
      attribute :transport_protocol_class, :kind_of => String, :required => nil
      attribute :debug, :equal_to => [true, false, 'true', 'false']
      attribute :enabled, :equal_to => [true, false, 'true', 'false'], :default => true
      attribute :description, :kind_of => String, :default => ''
      attribute :properties, :kind_of => Hash, :default => {}
      attribute :deployment_order, :kind_of => Fixnum, :default => 100

      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def resource_property_prefix
        "resources.mail-resource.#{self.name}."
      end

      def properties_to_record_in_create
        {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
      end

      def properties_to_set_in_create
        property_map = {'description' => self.description}

        collect_property_sets(resource_property_prefix, property_map)

        property_map['debug'] = self.debug
        property_map['enabled'] = self.enabled
        property_map['from'] = self.from
        property_map['host'] = self.host
        property_map['user'] = self.user
        property_map['store-protocol'] = self.store_protocol
        property_map['store-protocol-class'] = self.store_protocol_class
        property_map['transport-protocol'] = self.transport_protocol
        property_map['transport-protocol-class'] = self.transport_protocol_class

        property_map
      end

      def do_create
        args = []

        args << '--debug' << self.debug.to_s
        args << '--enabled' << self.enabled.to_s
        args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
        args << '--description' << self.description.to_s
        args << '--mailhost' << self.host.to_s
        args << '--mailuser' << self.user.to_s
        args << '--fromaddress' << self.from.to_s
        args << '--storeprotocol' << self.store_protocol.to_s if self.store_protocol
        args << '--storeprotocolclass' << self.store_protocol_class.to_s if self.store_protocol_class
        args << '--transprotocol' << self.transport_protocol.to_s if self.transport_protocol
        args << '--transprotocolclass' << self.transport_protocol_class.to_s if self.transport_protocol_class
        args << self.name.to_s

        context.exec('create-javamail-resource', args)
      end

      def do_destroy
        context.exec('delete-javamail-resource', [self.name])
      end

      def present?
        (context.exec('list-javamail-resources', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
