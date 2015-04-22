module Redfish
  module Tasks
    class AuthRealm < BaseResourceTask

      attribute :name, :kind_of => String, :required => true
      attribute :classname, :kind_of => String, :required => true
      attribute :properties, :kind_of => Hash, :default => {}

      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def immutable_local_properties
        ['classname']
      end

      def resource_property_prefix
        "configs.config.server-config.security-service.auth-realm.#{self.name}."
      end

      def properties_to_record_in_create
        {'name' => self.name}
      end

      def properties_to_set_in_create
        property_map = {}

        collect_property_sets(resource_property_prefix, property_map)

        property_map['classname'] = self.classname

        property_map
      end

      def do_create
        args = []

        args << '--classname' << self.classname.to_s
        args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
        args << self.name.to_s

        context.exec('create-auth-realm', args)
      end

      def do_destroy
        context.exec('delete-auth-realm', [self.name])
      end

      def present?
        (context.exec('list-auth-realms', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
