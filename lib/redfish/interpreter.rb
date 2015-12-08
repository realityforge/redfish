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

  # The class that takes a hash and translates it into a graph of tasks to execute.
  # The following is a typical example of the data translated by the interpreter
  #
  # {
  #   'libraries' => {
  #     'realm' => {
  #       'url' => '/some/path/lib/realm.jar'
  #     },
  #     'jdbcdriver' => {
  #       'type' => 'common',
  #       'url' => '/some/path/lib/mysql-connector-java-5.1.25-bin.jar'
  #     },
  #     'encryption' => {
  #       'type' => 'common',
  #       'url' => '/some/path/lib/jasypt-1.9.0.jar'
  #     }
  #   },
  #   'log_levels' => {'iris' => 'WARNING', 'iris.planner' => 'INFO'},
  #   'thread_pools' => {
  #     'thread-pool-1' => {
  #       'maxthreadpoolsize' => 200,
  #       'minthreadpoolsize' => 5,
  #       'idletimeout' => 900,
  #       'maxqueuesize' => 4096
  #     },
  #     'http-thread-pool' => {
  #       'maxthreadpoolsize' => 200,
  #       'minthreadpoolsize' => 5,
  #       'idletimeout' => 900,
  #       'maxqueuesize' => 4096
  #     },
  #     'admin-pool' => {
  #       'maxthreadpoolsize' => 50,
  #       'minthreadpoolsize' => 5,
  #       'maxqueuesize' => 256
  #     }
  #   },
  #   'iiop_listeners' => {
  #     'orb-listener-1' => {
  #       'enabled' => true,
  #       'iiopport' => 1072,
  #       'securityenabled' => false
  #     }
  #   },
  #   'context_services' => {
  #     'concurrent/MyAppContextService' => {
  #       'description' => 'My Apps ContextService'
  #     }
  #   },
  #   'managed_thread_factories' => {
  #     'concurrent/myThreadFactory' => {
  #       'threadpriority' => 12,
  #       'description' => 'My Thread Factory'
  #     }
  #   },
  #   'managed_executor_services' => {
  #     'concurrent/myExecutorService' => {
  #       'threadpriority' => 12,
  #       'description' => 'My Executor Service'
  #     }
  #   },
  #   'managed_scheduled_executor_services' => {
  #     'concurrent/myScheduledExecutorService' => {
  #       'corepoolsize' => 12,
  #       'description' => 'My Executor Service'
  #     }
  #   },
  #   'jdbc_connection_pools' => {
  #     'RealmPool' => {
  #       'datasourceclassname' => 'com.mysql.jdbc.jdbc2.optional.MysqlDataSource',
  #       'restype' => 'javax.sql.DataSource',
  #       'isconnectvalidatereq' => 'true',
  #       'validationmethod' => 'auto-commit',
  #       'ping' => 'true',
  #       'description' => 'Realm Pool',
  #       'properties' => {
  #         'Instance' => 'jdbc:mysql://devdb.somecompany.com:3306/realmdb',
  #         'ServerName' => 'devdb.somecompany.com',
  #         'User' => 'realmuser',
  #         'Password' => 'realmpw',
  #         'PortNumber' => '3306',
  #         'DatabaseName' => 'realmdb'
  #       },
  #       'resources' => {
  #         'jdbc/Realm' => {
  #           'description' => 'Resource for Realm Pool',
  #         }
  #       }
  #     },
  #     'AppPool' => {
  #       'datasourceclassname' => 'com.mysql.jdbc.jdbc2.optional.MysqlDataSource',
  #       'restype' => 'javax.sql.DataSource',
  #       'isconnectvalidatereq' => 'true',
  #       'validationmethod' => 'auto-commit',
  #       'ping' => 'true',
  #       'description' => 'App Pool',
  #       'properties' => {
  #         'Instance' => 'jdbc:mysql://devdb.somecompany.com:3306/appdb',
  #         'ServerName' => 'devdb.somecompany.com',
  #         'User' => 'appuser',
  #         'Password' => 'apppw',
  #         'PortNumber' => '3306',
  #         'DatabaseName' => 'appdb'
  #       }
  #       'resources' => {
  #         'jdbc/App' => {
  #           'description' => 'Resource for App Pool',
  #         }
  #       }
  #     }
  #   },
  #   'auth_realms' => {
  #     'custom-realm' => {
  #       'classname' => 'com.somecompany.realm.CustomRealm',
  #       'jaas-context' => 'customRealm',
  #       'properties' => {
  #         'jaas-context' => 'customRealm',
  #         'datasource' => 'jdbc/Realm',
  #         'groupQuery' => 'SELECT ...',
  #         'passwordQuery' => 'SELECT ...'
  #       }
  #     }
  #   },
  #   'applications' => {
  #     'myapp' => {
  #       'location' => "/opt/myapp/myapp.war",
  #       'context_root' => '/'
  #     }
  #   },
  #   'custom_resources' => {
  #     'env/myapp/timeout' => {
  #       'restype' => 'java.lang.Long',
  #       'value' => 300000
  #     },
  #     'env/myapp/mykey' => '123',
  #     'env/myapp/someString' => 'XYZ'
  #   }
  # }
  #
  # Most commonly this data is loaded from a json file via JSON.parse('infrastructure.json')
  class Interpreter
    class << self
      def interpret(run_context, data)
        Interpreter.new.interpret(run_context, data)
      end
    end

    def interpret(run_context, data)
      pre_interpret_actions(run_context)

      interpret_log_levels(run_context, data['log_levels']) if data['log_levels']

      interpret_log_attributes(run_context, data['log_attributes']) if data['log_attributes']

      psort(data['libraries']).values.each do |config|
        interpret_library(run_context, config)
      end

      psort(data['thread_pools']).each_pair do |key, config|
        interpret_thread_pool(run_context, key, config)
      end

      psort(data['iiop_listeners']).each_pair do |key, config|
        interpret_iiop_listener(run_context, key, config)
      end

      psort(data['context_services']).each_pair do |key, config|
        interpret_context_service(run_context, key, config)
      end

      psort(data['managed_thread_factories']).each_pair do |key, config|
        interpret_managed_thread_factory(run_context, key, config)
      end

      psort(data['managed_executor_services']).each_pair do |key, config|
        interpret_managed_executor_service(run_context, key, config)
      end

      psort(data['managed_scheduled_executor_services']).each_pair do |key, config|
        interpret_managed_scheduled_executor_service(config, key, run_context)
      end

      psort(data['properties']).each_pair do |key, config|
        interpret_property(run_context, key, config)
      end

      psort(data['auth_realms']).each_pair do |key, config|
        interpret_auth_realm(run_context, key, config)
      end

      psort(data['jms_hosts']).each_pair do |key, config|
        interpret_jms_hosts(run_context, key, config)
      end

      psort(data['jdbc_connection_pools']).each_pair do |key, config|
        interpret_jdbc_connection_pool(run_context, key, config)
      end

      psort(data['resource_adapters']).each_pair do |key, config|
        interpret_resource_adapter(run_context, key, config)
      end

      psort(data['jms_resources']).each_pair do |key, config|
        interpret_jms_resource(run_context, key, config)
      end

      psort(data['custom_resources']).each_pair do |key, config|
        interpret_custom_resource(run_context, key, config)
      end

      psort(data['javamail_resources']).each_pair do |key, config|
        interpret_javamail_resource(run_context, key, config)
      end

      psort(data['applications']).each_pair do |key, config|
        interpret_application(run_context, key, config)
      end

      post_interpret_actions(run_context)
    end

    private

    def pre_interpret_actions(run_context)
      run_context.task('property_cache').action(:create)
    end

    def post_interpret_actions(run_context)
      run_context.task('property_cache').action(:destroy)
    end

    def interpret_log_levels(run_context, config)
      run_context.task('log_levels', 'levels' => config).action(:set)
    end

    def interpret_log_attributes(run_context, config)
      run_context.task('log_attributes', 'attributes' => config).action(:set)
    end

    def interpret_library(run_context, config)
      run_context.task('library', params(config)).action(:create)
    end

    def interpret_thread_pool(run_context, key, config)
      run_context.task('thread_pool', params(config).merge('name' => key)).action(:create)
    end

    def interpret_iiop_listener(run_context, key, config)
      run_context.task('iiop_listener', params(config).merge('name' => key)).action(:create)
    end

    def interpret_context_service(run_context, key, config)
      run_context.task('context_service',
                       params(config).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_managed_thread_factory(run_context, key, config)
      run_context.task('managed_thread_factory',
                       params(config).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_managed_executor_service(run_context, key, config)
      run_context.task('managed_executor_service',
                       params(config).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_managed_scheduled_executor_service(config, key, run_context)
      run_context.task('managed_scheduled_executor_service',
                       params(config).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_property(run_context, key, config)
      run_context.task('property', 'name' => key, 'value' => config).action(:set)
    end

    def interpret_auth_realm(run_context, key, config)
      run_context.task('auth_realm', params(config).merge('name' => key)).action(:create)
    end

    def interpret_jms_hosts(run_context, key, config)
      run_context.task('jms_host', params(config).merge('name' => key)).action(:create)
    end

    def interpret_jdbc_connection_pool(run_context, key, config)
      params = config.dup
      params.delete('resources')

      run_context.task('jdbc_connection_pool',
                       params(params).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)

      psort(config['resources']).each_pair do |resource_key, resource_config|
        interpret_jdbc_resource(run_context, key, resource_key, resource_config)
      end
    end

    def interpret_jdbc_resource(run_context, connection_pool_key, key, config)
      run_context.task('jdbc_resource',
                       params(config).merge('connectionpoolid' => connection_pool_key,
                                                     'name' => key,
                                                     'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_resource_adapter(run_context, key, config)
      params = config.dup
      params.delete('connection_pools')
      params.delete('admin_objects')
      run_context.task('resource_adapter', params(params).merge('name' => key)).action(:create)

      psort(config['connection_pools']).each_pair do |pool_key, pool_config|
        interpret_connector_connection_pool(run_context, key, pool_key, pool_config)
      end

      psort(config['admin_objects']).each_pair do |admin_object_key, admin_object_config|
        interpret_admin_object(run_context, key, admin_object_key, admin_object_config)
      end
    end

    def interpret_connector_connection_pool(run_context, resource_adapter_key, key, config)
      pool_params = config.dup
      pool_params.delete('resources')
      run_context.task('connector_connection_pool',
                       params(pool_params).merge('resource_adapter_name' => resource_adapter_key,
                                                 'name' => key,
                                                 'deployment_order' => priority_value(config))).
        action(:create)

      psort(config['resources']).each_pair do |resource_key, resource_config|
        interpret_connector_resource(run_context, key, resource_key, resource_config)
      end
    end

    def interpret_connector_resource(run_context, pool_key, key, config)
      run_context.task('connector_resource',
                       params(config).merge('connector_pool_name' => pool_key,
                                                     'name' => key,
                                                     'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_admin_object(run_context, resource_adapter_key, key, config)
      run_context.task('admin_object',
                       params(config).merge('resource_adapter_name' => resource_adapter_key,
                                                         'name' => key,
                                                         'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_jms_resource(run_context, key, config)
      run_context.task('jms_resource',
                       params(config).merge('name' => key, 'deployment_order' => priority_value(config))).
        action(:create)
    end

    def interpret_custom_resource(run_context, key, config)
      params = config.dup
      if params['restype'].nil?
        params['restype'] = 'java.lang.Boolean' if params['value'].is_a?(TrueClass) || params['value'].is_a?(FalseClass)
        params['restype'] = 'java.lang.Integer' if params['value'].is_a?(Fixnum)
        params['restype'] = 'java.lang.Long' if params['value'].is_a?(Bignum)
        params['restype'] = 'java.lang.Float' if params['value'].is_a?(Float)
      end

      run_context.task('custom_resource', params(params).merge('name' => key, 'deployment_order' => priority_value(config))).action(:create)
    end

    def interpret_javamail_resource(run_context, key, config)
      run_context.task('javamail_resource', params(config).merge('name' => key, 'deployment_order' => priority_value(config))).action(:create)
    end

    def interpret_application(run_context, key, config)
      params = config.dup
      params.delete('web_env_entries')
      run_context.task('application', params(params).merge('name' => key, 'deployment_order' => priority_value(config))).action(:create)
      psort(config['web_env_entries']).each_pair do |entry_key, entry_config|
        run_context.task('web_env_entry', params(entry_config).merge('application' => key, 'name' => entry_key)).action(:create)
      end
    end

    def params(config)
      params = config.nil? ? {} : config.dup
      params.delete('priority')
      params
    end

    def psort(hash)
      hash.nil? ? {} : Hash[hash.sort_by { |key, value| "#{"%04d" % priority_value(value)}#{key}" }]
    end

    def priority_value(value)
      value.is_a?(Hash) && value['priority'] ? value['priority'] : 100
    end
  end
end
