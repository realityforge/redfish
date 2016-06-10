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

        private

        def mirror_jms_resources(data)
          data['jms_resources'].each_pair do |key, jms_config|
            next if key == 'managed'

            if %w(javax.jms.ConnectionFactory javax.jms.TopicConnectionFactory javax.jms.QueueConnectionFactory).include?(jms_config['restype'])
              pool = data['resource_adapters']['jmsra']['connection_pools']["#{key}-Connection-Pool"]
              pool['connection_definition_name'] = jms_config['restype']
              resource = pool['resources'][key]
              jms_config['properties'].each_pair do |property_key, property_value|
                if %w(AddressList ReconnectEnabled ReconnectAttempts ReconnectInterval AddressListBehavior AddressListIterations)
                  pool['properties'][property_key] = property_value
                else
                  resource['properties'][property_key] = property_value
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
