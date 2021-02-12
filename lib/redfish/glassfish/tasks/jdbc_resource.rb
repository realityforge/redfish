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
      class JdbcResource < BaseResourceTask
        PROPERTY_PREFIX = 'resources.jdbc-resource.'

        private

        attribute :connectionpoolid, :kind_of => String, :identity_field => true
        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :enabled, :type => :boolean, :default => true
        attribute :description, :kind_of => String, :default => ''
        attribute :object_type, :kind_of => String, :default => 'user'
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Integer, :default => 100

        action :create do
          raise 'connectionpoolid property not set' unless self.connectionpoolid
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
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
          property_map['pool-name'] = self.connectionpoolid

          property_map
        end

        def do_create
          raise "Unable to create jdbc-resource where object_type is not 'user'" unless self.object_type == 'user'

          args = []

          args << '--enabled' << self.enabled.to_s
          args << '--connectionpoolid' << self.connectionpoolid.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description.to_s
          args << self.name.to_s

          context.exec('create-jdbc-resource', args)
        end

        def do_destroy
          context.exec('delete-jdbc-resource', [self.name])
        end

        def present?
          (context.exec('list-jdbc-resources', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
