module Redfish
  module Tasks
    class CustomResource < BaseResourceTask

      attribute :name, :kind_of => String, :required => true
      attribute :restype, :kind_of => String, :default => 'java.lang.String'
      attribute :factoryclass,
                :kind_of => String,
                :default => 'org.glassfish.resources.custom.factory.PrimitivesAndStringFactory'
      attribute :enabled, :equal_to => [true, false, 'true', 'false'], :default => true
      attribute :description, :kind_of => String, :default => ''
      attribute :properties, :kind_of => Hash, :default => {}
      attribute :value, :kind_of => String, :default => nil
      attribute :deployment_order, :kind_of => Fixnum, :default => 100

      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def resource_property_prefix
        "resources.custom-resource.#{self.name}."
      end

      def properties_to_record_in_create
        {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
      end

      def properties_to_set_in_create
        property_map = {'description' => self.description}

        collect_property_sets(resource_property_prefix, property_map)
        property_map['property.value'] = self.value if self.value

        property_map['enabled'] = self.enabled
        property_map['factory-class'] = self.factoryclass
        property_map['res-type'] = self.restype

        property_map
      end

      def do_create
        args = []

        args << '--enabled' << self.enabled.to_s
        args << '--restype' << self.restype.to_s
        args << '--factoryclass' << self.factoryclass.to_s
        args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
        args << '--description' << self.description.to_s
        args << self.name.to_s

        context.exec('create-custom-resource', args)
      end

      def do_destroy
        context.exec('delete-custom-resource', [self.name])
      end

      def present?
        (context.exec('list-custom-resources', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
