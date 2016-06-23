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
      class ConnectorConnectionPool < BaseResourceTask
        PROPERTY_PREFIX = 'resources.connector-connection-pool.'

        private

        ConnectorAttribute = Struct.new('ConnectorAttribute', :key, :type, :cmdline_arg, :property_key, :default_value, :options)

        ATTRIBUTES = []

        def self.cmdline_arg(key, options)
          options.delete(:cmdline_arg) || key.to_s.gsub('_', '')
        end

        def self.at(key, type, property_key, default_value, options)
          opt = options.dup
          ATTRIBUTES << ConnectorAttribute.new(key, type, cmdline_arg(key, opt), property_key, default_value, opt)
        end

        def self.str(key, property_key, default_value = '', options = {})
          at(key, :string, property_key, default_value, options)
        end

        def self.num(key, property_key, default_value = 0, options = {})
          at(key, :numeric, property_key, default_value, options)
        end

        def self.bool(key, property_key, default_value = true, options = {})
          at(key, :boolean, property_key, default_value, options)
        end

        def self.opt(key, property_key, values, default_value, options = {})
          at(key, values, property_key, default_value, options)
        end

        str(:resource_adapter_name, 'resource-adapter-name', nil, :cmdline_arg => 'raname', :identity_field => true)
        str(:connection_definition_name, 'connection-definition-name', nil, :required => true, :cmdline_arg => 'connectiondefinition')

        num(:steady_pool_size, 'steady-pool-size', 1)
        num(:max_pool_size, 'max-pool-size', 250)
        num(:max_wait, 'max-wait-time-in-millis', 60000)
        num(:pool_resize, 'pool-resize-quantity', 2)
        num(:idle_timeout, 'idle-timeout-in-seconds', 300)
        num(:leak_timeout, 'connection-leak-timeout-in-seconds')
        num(:validate_at_most_once_period_in_seconds, 'validate-atmost-once-period-in-seconds', 0, :cmdline_arg => 'validateatmostonceperiod')
        num(:max_connection_usage_count, 'max-connection-usage-count')
        num(:creation_retry_attempts, 'connection-creation-retry-attempts')
        num(:creation_retry_interval, 'connection-creation-retry-interval-in-seconds', 10)

        bool(:is_connection_validation_required, 'is-connection-validation-required', true, :cmdline_arg => 'isconnectvalidatereq')
        bool(:fail_connection, 'fail-all-connections', false)
        bool(:leak_reclaim, 'connection-leak-reclaim', false)
        bool(:lazy_connection_enlistment, 'lazy-connection-enlistment', false)
        bool(:lazy_connection_association, 'lazy-connection-association', false)
        bool(:associate_with_thread, 'associate-with-thread', false)
        bool(:match_connections, 'match-connections')
        bool(:ping, 'ping')
        bool(:pooling, 'pooling')

        opt(:transaction_support,
            'transaction-support',
            %w(XATransaction LocalTransaction NoTransaction),
            nil)

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        ATTRIBUTES.each do |attr|
          if attr.type == :string
            attribute attr.key, attr.options.merge(:kind_of => String, :default => attr.default_value)
          elsif attr.type == :numeric
            attribute attr.key, attr.options.merge(:type => :integer, :default => attr.default_value)
          elsif attr.type == :boolean
            attribute attr.key, attr.options.merge(:type => :boolean, :default => attr.default_value)
          elsif attr.type.is_a?(Array)
            attribute attr.key, attr.options.merge(:equal_to => attr.type, :default => attr.default_value)
          end
        end

        private

        action :create do
          raise 'resource_adapter_name property not set' unless self.resource_adapter_name

          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => 'user', 'name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}
          collect_property_sets(resource_property_prefix, property_map)

          ATTRIBUTES.each do |attr|
            property_map[attr.property_key] = self.send(attr.key)
          end
          property_map['description'] = self.description
          property_map
        end

        def do_create
          args = []
          ATTRIBUTES.each do |attr|
            args << "--#{attr.cmdline_arg}=#{self.send(attr.key)}"
          end

          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description
          args << self.name

          context.exec('create-connector-connection-pool', args)
        end

        def do_destroy
          args = []
          args << '--cascade=true'
          args << self.name
          context.exec('delete-connector-connection-pool', args)
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-connector-connection-pools', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
