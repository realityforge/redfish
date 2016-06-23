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
      class ConnectorResource < BaseResourceTask
        PROPERTY_PREFIX = 'resources.connector-resource.'

        private

        attribute :connector_pool_name, :kind_of => String, :identity_field => true
        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :object_type, :equal_to => %w(user system-instance system-admin system-all), :default => 'user'

        attribute :enabled, :type => :boolean, :default => true
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        action :create do
          raise 'connector_pool_name property not set' unless self.connector_pool_name

          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def immutable_local_properties
          ['object-type']
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => self.object_type, 'jndi-name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['description'] = self.description
          property_map['enabled'] = self.enabled
          property_map['pool-name'] = self.connector_pool_name

          property_map
        end

        def do_create
          args = []
          args << '--enabled' << self.enabled.to_s
          args << '--objecttype' << self.object_type.to_s
          args << '--poolname' << self.connector_pool_name.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description.to_s
          args << self.name.to_s

          context.exec('create-connector-resource', args)
        end

        def do_destroy
          context.exec('delete-connector-resource', [self.name])
        end

        def present?
          (context.exec('list-connector-resources', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
