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

require File.expand_path('../../../helper', __FILE__)

class Redfish::TestPreInterpreter < Redfish::TestCase
  def test_pre_interpret_no_data
    input = {}
    expected = {'jms_resources' => {}, 'properties' => {}}
    assert_pre_interpret(expected, input)
  end

  def test_pre_interpret_jms_service
    input =
      {
        'properties' =>
          {
            'configs.config.server-config.jms-service.addresslist-behavior' => 'random',
            'configs.config.server-config.jms-service.addresslist-iterations' => '3',
            'configs.config.server-config.jms-service.init-timeout-in-seconds' => '60',
            'configs.config.server-config.jms-service.reconnect-attempts' => '3',
            'configs.config.server-config.jms-service.reconnect-enabled' => 'true',
            'configs.config.server-config.jms-service.reconnect-interval-in-seconds' => '60',
            'configs.config.server-config.jms-service.type' => 'REMOTE',
            'configs.config.server-config.jms-service.default-jms-host' => 'Host1',
          },
        'jms_hosts' =>
          {
            'managed' => true,
            'Host1' => {
              'host' => 'mq.example.com',
              'port' => '7676',
              'admin_username' => 'bob',
              'admin_password' => 'secret'
            },
            'Host2' => {
              'host' => 'mq2.example.com',
              'port' => '7675',
              'admin_username' => 'bob2',
              'admin_password' => 'secret2'
            }
          }
      }
    expected =
      {
        'properties' =>
          {
            'configs.config.server-config.jms-service.addresslist-behavior' => 'random',
            'configs.config.server-config.jms-service.addresslist-iterations' => '3',
            'configs.config.server-config.jms-service.init-timeout-in-seconds' => '60',
            'configs.config.server-config.jms-service.reconnect-attempts' => '3',
            'configs.config.server-config.jms-service.reconnect-enabled' => 'true',
            'configs.config.server-config.jms-service.reconnect-interval-in-seconds' => '60',
            'configs.config.server-config.jms-service.type' => 'REMOTE',
            'configs.config.server-config.jms-service.default-jms-host' => 'Host1',
          },
        'jms_hosts' =>
          {
            'managed' => true,
            'Host1' => {
              'host' => 'mq.example.com',
              'port' => '7676',
              'admin_username' => 'bob',
              'admin_password' => 'secret'
            },
            'Host2' => {
              'host' => 'mq2.example.com',
              'port' => '7675',
              'admin_username' => 'bob2',
              'admin_password' => 'secret2'
            }
          },
        'jms_resources' => {},
        'resource_adapters' =>
          {
            'jmsra' =>
              {
                'properties' =>
                  {
                    'AddressListBehavior' => 'random',
                    'AddressListIterations' => '3',
                    'BrokerStartTimeOut' => '60',
                    'ReconnectAttempts' => '3',
                    'ReconnectEnabled' => 'true',
                    'ReconnectInterval' => '60',
                    'BrokerType' => 'REMOTE',
                    'ConnectionURL' => 'mq://mq.example.com:7676',
                    'AdminUsername' => 'bob',
                    'AdminPassword' => 'secret'
                  }
              }
          }
      }
    assert_pre_interpret(expected, input)
  end

  def test_pre_interpret_jms_destination_resources
    input =
      {
        'jms_resources' =>
          {
            'managed' => true,
            'myapp/jms/MyTopic' => {
              'properties' => {
                'Name' => 'MyTopic'
              },
              'restype' => 'javax.jms.Topic'
            },
            'myapp/jms/MyQueue' => {
              'properties' => {
                'Name' => 'MyQueue'
              },
              'restype' => 'javax.jms.Queue'
            }
          }
      }
    expected = {
      'jms_resources' =>
        {
          'managed' => true,
          'myapp/jms/MyTopic' => {'properties' => {'Name' => 'MyTopic'}, 'restype' => 'javax.jms.Topic'},
          'myapp/jms/MyQueue' => {'properties' => {'Name' => 'MyQueue'}, 'restype' => 'javax.jms.Queue'}
        },
      'resource_adapters' =>
        {
          'jmsra' =>
            {
              'admin_objects' =>
                {
                  'myapp/jms/MyTopic' => {'restype' => 'javax.jms.Topic', 'properties' => {'Name' => 'MyTopic'}},
                  'myapp/jms/MyQueue' => {'restype' => 'javax.jms.Queue', 'properties' => {'Name' => 'MyQueue'}}
                }
            }
        },
      'properties' => {}
    }
    assert_pre_interpret(expected, input)
  end

  def test_pre_interpret_jms_factory_resources
    input =
      {
        'jms_resources' =>
          {
            'managed' => true,
            'myapp/jms/ConnectionFactory' => {
              'properties' => {
                'AddressList' => 'mq://mq.example.com:7676/jms',
                'AddressListBehavior' => 'random',
                'AddressListIterations' => '3',
                'ClientId' => 'MyApp',
                'Password' => 'secret',
                'ReconnectAttempts' => 3,
                'ReconnectEnabled' => true,
                'ReconnectInterval' => 5000,
                'UserName' => 'MyAppUser'
              },
              'restype' => 'javax.jms.ConnectionFactory'
            },
            'myapp/jms/TopicConnectionFactory' => {
              'properties' => {
                'AddressList' => 'mq://mq.example.com:7676/jms',
                'AddressListBehavior' => 'random',
                'AddressListIterations' => '3',
                'ClientId' => 'MyApp',
                'Password' => 'secret',
                'ReconnectAttempts' => 3,
                'ReconnectEnabled' => true,
                'ReconnectInterval' => 5000,
                'UserName' => 'MyAppUser'
              },
              'restype' => 'javax.jms.TopicConnectionFactory'
            },
            'myapp/jms/QueueConnectionFactory' => {
              'properties' => {
                'AddressList' => 'mq://mq.example.com:7676/jms',
                'AddressListBehavior' => 'random',
                'AddressListIterations' => '3',
                'ClientId' => 'MyApp',
                'Password' => 'secret',
                'ReconnectAttempts' => 3,
                'ReconnectEnabled' => true,
                'ReconnectInterval' => 5000,
                'UserName' => 'MyAppUser'
              },
              'restype' => 'javax.jms.QueueConnectionFactory'
            }
          }
      }
    expected = {
      'jms_resources' =>
        {
          'managed' => true,
          'myapp/jms/ConnectionFactory' =>
            {
              'properties' =>
                {
                  'AddressList' => 'mq://mq.example.com:7676/jms',
                  'AddressListBehavior' => 'random',
                  'AddressListIterations' => '3',
                  'ClientId' => 'MyApp',
                  'Password' => 'secret',
                  'ReconnectAttempts' => 3,
                  'ReconnectEnabled' => true,
                  'ReconnectInterval' => 5000,
                  'UserName' => 'MyAppUser'},
              'restype' => 'javax.jms.ConnectionFactory'
            },
          'myapp/jms/TopicConnectionFactory' =>
            {
              'properties' =>
                {
                  'AddressList' => 'mq://mq.example.com:7676/jms',
                  'AddressListBehavior' => 'random',
                  'AddressListIterations' => '3',
                  'ClientId' => 'MyApp',
                  'Password' => 'secret',
                  'ReconnectAttempts' => 3,
                  'ReconnectEnabled' => true,
                  'ReconnectInterval' => 5000,
                  'UserName' => 'MyAppUser'
                },
              'restype' => 'javax.jms.TopicConnectionFactory'
            },
          'myapp/jms/QueueConnectionFactory' =>
            {
              'properties' =>
                {
                  'AddressList' => 'mq://mq.example.com:7676/jms',
                  'AddressListBehavior' => 'random',
                  'AddressListIterations' => '3',
                  'ClientId' => 'MyApp',
                  'Password' => 'secret',
                  'ReconnectAttempts' => 3,
                  'ReconnectEnabled' => true,
                  'ReconnectInterval' => 5000,
                  'UserName' => 'MyAppUser'},
              'restype' => 'javax.jms.QueueConnectionFactory'
            }
        },
      'resource_adapters' =>
        {
          'jmsra' =>
            {
              'connection_pools' =>
                {
                  'myapp/jms/ConnectionFactory-Connection-Pool' =>
                    {
                      'connection_definition_name' => 'javax.jms.ConnectionFactory',
                      'resources' => {'myapp/jms/ConnectionFactory' => {}},
                      'properties' =>
                        {
                          'AddressList' => 'mq://mq.example.com:7676/jms',
                          'AddressListBehavior' => 'random',
                          'AddressListIterations' => '3',
                          'ClientId' => 'MyApp',
                          'Password' => 'secret',
                          'ReconnectAttempts' => 3,
                          'ReconnectEnabled' => true,
                          'ReconnectInterval' => 5000,
                          'UserName' => 'MyAppUser'
                        }
                    },
                  'myapp/jms/TopicConnectionFactory-Connection-Pool' =>
                    {
                      'connection_definition_name' => 'javax.jms.TopicConnectionFactory',
                      'resources' => {'myapp/jms/TopicConnectionFactory' => {}},
                      'properties' =>
                        {
                          'AddressList' => 'mq://mq.example.com:7676/jms',
                          'AddressListBehavior' => 'random',
                          'AddressListIterations' => '3',
                          'ClientId' => 'MyApp',
                          'Password' => 'secret',
                          'ReconnectAttempts' => 3,
                          'ReconnectEnabled' => true,
                          'ReconnectInterval' => 5000,
                          'UserName' => 'MyAppUser'
                        }
                    },
                  'myapp/jms/QueueConnectionFactory-Connection-Pool' =>
                    {
                      'connection_definition_name' => 'javax.jms.QueueConnectionFactory',
                      'resources' => {'myapp/jms/QueueConnectionFactory' => {}},
                      'properties' =>
                        {
                          'AddressList' => 'mq://mq.example.com:7676/jms',
                          'AddressListBehavior' => 'random',
                          'AddressListIterations' => '3',
                          'ClientId' => 'MyApp',
                          'Password' => 'secret',
                          'ReconnectAttempts' => 3,
                          'ReconnectEnabled' => true,
                          'ReconnectInterval' => 5000,
                          'UserName' => 'MyAppUser'
                        }
                    }
                }
            }
        },
      'properties' => {}
    }
    assert_pre_interpret(expected, input)
  end

  private

  def assert_pre_interpret(expected, input)
    output = Redfish::Interpreter::PreInterpreter.pre_interpret(Redfish::Mash.from(input))
    assert_equal output.to_h, expected
  end
end
