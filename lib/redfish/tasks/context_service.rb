module Redfish
  module Tasks
    class ContextService < BaseResourceTask

      attribute :name, :kind_of => String, :required => true

      # Determines whether the resource is enabled at runtime.
      attribute :enabled, :equal_to => [true, false, 'true', 'false'], :default => true
      # Determines whether container contexts are propagated to threads. If set to true, the contexts specified in the --contextinfo option are propagated. If set to false, no contexts are propagated and the --contextinfo option is ignored.
      attribute :context_info_enabled, :equal_to => [true, false, 'true', 'false'], :default => true
      # Specifies individual container contexts to propagate to threads. Valid values are Classloader, JNDI, Security, and WorkArea. Values are specified in a comma-separated list and are case-insensitive. All contexts are propagated by default.
      attribute :context_info, :kind_of => String, :default => 'Classloader,JNDI,Security,WorkArea'
      # Descriptive details about the resource.
      attribute :description, :kind_of => String, :default => ''
      attribute :properties, :kind_of => Hash, :default => {}
      attribute :deploymentorder, :kind_of => Fixnum, :default => 100
      
      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def resource_property_prefix
        "resources.context-service.#{self.name}."
      end

      def properties_to_record_in_create
        {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
      end

      def properties_to_set_in_create
        property_map = {}

        collect_property_sets(resource_property_prefix, property_map)

        property_map['description'] = self.description
        property_map['context-info-enabled'] = self.context_info_enabled
        property_map['context-info'] = self.context_info
        property_map['enabled'] = self.enabled

        property_map
      end

      def do_create
        args = []

        args << '--enabled' << self.enabled.to_s
        args << '--contextinfoenabled' << self.context_info_enabled.to_s
        args << '--contextinfo' << self.context_info.to_s
        args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
        args << '--description' << self.description.to_s
        args << self.name.to_s

        context.exec('create-context-service', args)
      end

      def do_destroy
        context.exec('delete-context-service', [self.name])
      end

      def present?
        (context.exec('list-context-services', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
