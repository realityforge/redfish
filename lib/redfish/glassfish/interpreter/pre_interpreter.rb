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

module Redfish #nodoc
  module Interpreter #nodoc

    # Class invoked prior to interepretation to prepare data for interpretation
    # This is usually used to mirror resources from jms_service, jms_host, jms_resources etc to jmsra resource adapter
    class PreInterpreter
      class << self
        def pre_interpret(data)
          mirror_jms_resources(data)
        end

        # Any entries in data parameter that are not explicitly
        # configured as managed are marked as unmanaged
        def mark_as_unmanaged(data)
          %w(
        domain jvm_options libraries realm_types thread_pools iiop_listeners context_services managed_thread_factories
        managed_executor_services managed_scheduled_executor_services auth_realms jms_hosts
        jdbc_connection_pools resource_adapters jms_resources custom_resources javamail_resources
        applications system_properties
      ).each do |key|
            unless data.has_key?(key) && data[key].has_key?('managed')
              data[key] = {} unless data.has_key?(key)
              data[key]['managed'] = false
            end
          end

          data['logging'] = {} unless data.has_key?('logging')
          logging = data['logging']
          logging['levels'] = {} unless logging.has_key?('levels')
          logging['levels']['managed'] = false unless logging['levels'].has_key?('managed')
          logging['attributes'] = {} unless logging.has_key?('attributes')
          logging['attributes']['managed'] = false unless logging['attributes'].has_key?('managed')

          data['applications'] = {} unless data.has_key?('applications')
          data['applications']['managed'] = false unless data['applications'].has_key?('managed')

          data['applications'].each_pair do |key, application_config|
            next if key == 'managed' && (application_config.is_a?(TrueClass) || application_config.is_a?(FalseClass))
            application_config['web_env_entries'] = {} unless application_config.has_key?('web_env_entries')
            application_config['web_env_entries']['managed'] = false unless application_config['web_env_entries'].has_key?('managed')
          end

          data['jdbc_connection_pools'] = {} unless data.has_key?('jdbc_connection_pools')
          data['jdbc_connection_pools']['managed'] = false unless data['jdbc_connection_pools'].has_key?('managed')

          data['jdbc_connection_pools'].each_pair do |key, config|
            next if key == 'managed' && (config.is_a?(TrueClass) || config.is_a?(FalseClass))
            config['resources'] = {} unless config.has_key?('resources')
            config['resources']['managed'] = false unless config['resources'].has_key?('managed')
          end
          data['resource_adapters'] = {} unless data.has_key?('resource_adapters')
          data['resource_adapters'].each_pair do |key, config|
            next if key == 'managed' && (config.is_a?(TrueClass) || config.is_a?(FalseClass))

            if config.has_key?('connection_pools')
              config['connection_pools'].each_pair do |pool_key, pool_config|
                next if pool_key == 'managed' && (pool_config.is_a?(TrueClass) || pool_config.is_a?(FalseClass))

                pool_config['resources'] = {} unless pool_config.has_key?('resources')
                pool_config['resources']['managed'] = false unless pool_config['resources'].has_key?('managed')
              end
            else
              config['connection_pools'] = {}
            end
            config['connection_pools']['managed'] = false unless config['connection_pools'].has_key?('managed')
            config['admin_objects'] = {} unless config.has_key?('admin_objects')
            config['admin_objects']['managed'] = false unless config['admin_objects'].has_key?('managed')
          end
        end

        private

        def mirror_jms_resources(data)
          data['jms_resources'].each_pair do |key, jms_config|
            next if key == 'managed'

            if %w(javax.jms.ConnectionFactory javax.jms.TopicConnectionFactory javax.jms.QueueConnectionFactory).include?(jms_config['restype'])
              pool = data['resource_adapters']['jmsra']['connection_pools']["#{key}-Connection-Pool"]
              pool['connection_definition_name'] = jms_config['restype']
              # Force the creation of the resource with next line
              pool['resources'][key]
              jms_config['properties'].each_pair do |property_key, property_value|
                if Redfish::Tasks::Glassfish::JmsResource::FACTORY_PROPERTIES.include?(property_key)
                  pool['resources'][key]['properties'][property_key] = property_value
                else
                  pool[property_key] = property_value
                end
              end
            else
              admin_object = data['resource_adapters']['jmsra']['admin_objects'][key]
              admin_object['restype'] = jms_config['restype']
              admin_object['description'] = jms_config['description'] if jms_config.key?('description')
              jms_config['properties'].each_pair do |property_key, property_value|
                admin_object['properties'][property_key] = property_value
              end
            end
          end
          property_map = {
            'configs.config.server-config.jms-service.addresslist-behavior' => 'AddressListBehavior',
            'configs.config.server-config.jms-service.addresslist-iterations' => 'AddressListIterations',
            'configs.config.server-config.jms-service.init-timeout-in-seconds' => 'BrokerStartTimeOut',
            'configs.config.server-config.jms-service.reconnect-attempts' => 'ReconnectAttempts',
            'configs.config.server-config.jms-service.reconnect-enabled' => 'ReconnectEnabled',
            'configs.config.server-config.jms-service.reconnect-interval-in-seconds' => 'ReconnectInterval',
            'configs.config.server-config.jms-service.type' => 'BrokerType',
          }
          data['properties'].each_pair do |key, value|
            simple_value = value.is_a?(Hash) ? value['value'] : value
            mapped_property = property_map[key]
            if mapped_property
              data['resource_adapters']['jmsra']['properties'][mapped_property] = simple_value
            end
            if key == 'configs.config.server-config.jms-service.default-jms-host' && data['jms_hosts'].key?(simple_value)
              if data['jms_hosts'][simple_value].key?('host') && data['jms_hosts'][simple_value].key?('port')
                data['resource_adapters']['jmsra']['properties']['ConnectionURL'] = "mq://#{data['jms_hosts'][simple_value]['host']}:#{data['jms_hosts'][simple_value]['port']}"
              end
              data['resource_adapters']['jmsra']['properties']['AdminUsername'] = data['jms_hosts'][simple_value]['admin_username'] if data['jms_hosts'][simple_value].key?('admin_username')
              data['resource_adapters']['jmsra']['properties']['AdminPassword'] = data['jms_hosts'][simple_value]['admin_password'] if data['jms_hosts'][simple_value].key?('admin_password')
            end
          end
          data
        end
      end
    end
  end
end
