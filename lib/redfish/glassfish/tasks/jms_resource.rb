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

module Redfish
  module Tasks
    module Glassfish
      class JmsResource < BaseResourceTask
        DESTINATION_PROPERTIES = %w(Name Description)
        FACTORY_PROPERTIES = %w(ClientId AddressList UserName Password ReconnectEnabled ReconnectAttempts ReconnectInterval AddressListBehavior AddressListIterations)
        POOL_PROPERTIES = %w(steady_pool_size max_pool_size max_wait pool_resize idle_timeout leak_timeout validate_at_most_once_period_in_seconds max_connection_usage_count creation_retry_attempts creation_retry_interval is_connection_validation_required fail_connection leak_reclaim lazy_connection_enlistment lazy_connection_association associate_with_thread match_connections ping pooling transaction_support)

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :restype, :equal_to => %w(javax.jms.Topic javax.jms.Queue javax.jms.ConnectionFactory javax.jms.TopicConnectionFactory javax.jms.QueueConnectionFactory)
        attribute :enabled, :type => :boolean, :default => true
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        action :create do
          raise 'The property restype must be set for jms resource' if self.restype.nil?
          self.properties.keys.each do |k|
            raise "The property '#{k}' is not valid for the resource type '#{restype}'. Valid properties include: #{valid_properties.inspect}" unless valid_properties.include?(k)
          end

          create(resource_property_prefix)
        end

        action :destroy do
          destroy(destination_resource_prefix)
          destroy(connection_factory_prefix)
        end

        def valid_properties
          if %w(javax.jms.Topic javax.jms.Queue).include?(self.restype)
            DESTINATION_PROPERTIES
          else
            FACTORY_PROPERTIES + POOL_PROPERTIES
          end
        end

        def resource_property_prefix
          if %w(javax.jms.Topic javax.jms.Queue).include?(self.restype)
            destination_resource_prefix
          else
            connection_factory_prefix
          end
        end

        def connection_factory_prefix
          "resources.connector-resource.#{self.name}."
        end

        def destination_resource_prefix
          "resources.admin-object-resource.#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          if %w(javax.jms.Topic javax.jms.Queue).include?(self.restype)
            collect_property_sets(resource_property_prefix, property_map)
          else
            props = {}
            self.properties.keys.select{|k| FACTORY_PROPERTIES.include?(k)}.each do |k|
              props[k] = self.properties[k]
            end
            collect_property_sets(resource_property_prefix, property_map, props)
          end

          property_map['description'] = self.description
          property_map['enabled'] = self.enabled

          if %w(javax.jms.Topic javax.jms.Queue).include?(self.restype)
            property_map['res-type'] = self.restype
            property_map['res-adapter'] = 'jmsra'
            if self.restype == 'javax.jms.Queue'
              property_map['class-name'] = 'com.sun.messaging.Queue'
            else
              property_map['class-name'] = 'com.sun.messaging.Topic'
            end
          end

          property_map
        end

        def do_create
          args = []

          args << '--enabled' << self.enabled.to_s
          args << '--restype' << self.restype.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description.to_s
          args << self.name.to_s

          context.exec('create-jms-resource', args)
        end

        def do_destroy
          context.exec('delete-jms-resource', [self.name])
        end

        def present?
          (context.exec('list-jms-resources', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
