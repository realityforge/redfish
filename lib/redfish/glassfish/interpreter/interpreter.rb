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
  #   'logging' => {
  #     'default_attributes' => true,
  #     'attributes' => {'handlers' => 'java.util.logging.ConsoleHandler'}
  #     'default_levels' => true,
  #     'levels' => {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
  #   },
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
  module Interpreter
    class << self

      def interpret(run_context, input, options = {})
        mash = Mash.from(input)

        Redfish::Interpreter::PreInterpreter.pre_interpret(mash)
        Redfish::Interpreter::PreInterpreter.mark_as_unmanaged(mash) if options[:update_only]

        data = Redfish::Interpreter::Interpolater.interpolate(run_context.app_context, mash.to_h)

        interpret_options = data['config'] || {}

        domain_options = domain_options(data['domain'] || {})

        if managed?(data['domain'])
          run_context.task('domain', domain_options).action(:create)
          run_context.task('domain', domain_options).action(:start)
          run_context.task('domain', domain_options).action(:enable_secure_admin) if run_context.app_context.domain_secure
          run_context.task('domain', domain_options).action(:ensure_active)
        end
        run_context.task('property_cache').action(:create)

        interpret_system_facilities(run_context, data, domain_options)

        context_services = psort(data['context_services'])
        context_services.each_pair do |key, config|
          interpret_context_service(run_context, key, config)
        end

        managed_thread_factories = psort(data['managed_thread_factories'])
        managed_thread_factories.each_pair do |key, config|
          interpret_managed_thread_factory(run_context, key, config)
        end

        managed_executor_services = psort(data['managed_executor_services'])
        managed_executor_services.each_pair do |key, config|
          interpret_managed_executor_service(run_context, key, config)
        end

        managed_scheduled_executor_services = psort(data['managed_scheduled_executor_services'])
        managed_scheduled_executor_services.each_pair do |key, config|
          interpret_managed_scheduled_executor_service(config, key, run_context)
        end

        jdbc_connection_pools = psort(data['jdbc_connection_pools'])
        jdbc_connection_pools.each_pair do |key, config|
          interpret_jdbc_connection_pool(run_context, key, config)
        end

        resource_adapters = psort(data['resource_adapters'])
        resource_adapters.each_pair do |key, config|
          interpret_resource_adapter(run_context, key, config)
        end
        restart_domain_if_required(run_context, domain_options)

        psort(data['jms_resources']).each_pair do |key, config|
          interpret_jms_resource(run_context, key, config)
        end

        custom_resources = psort(data['custom_resources'])
        custom_resources.each_pair do |key, config|
          interpret_custom_resource(run_context, key, config)
        end

        javamail_resources = psort(data['javamail_resources'])
        javamail_resources.each_pair do |key, config|
          interpret_javamail_resource(run_context, key, config)
        end

        applications = psort(data['applications'])
        applications.each_pair do |key, config|
          interpret_application(run_context, key, config)
        end

        if managed?(data['applications'])
          run_context.task('application_cleaner', 'expected' => applications.keys).action(:clean)
        end

        if managed?(data['javamail_resources'])
          run_context.task('javamail_resource_cleaner', 'expected' => javamail_resources.keys).action(:clean)
        end

        if managed?(data['custom_resources'])
          run_context.task('custom_resource_cleaner', 'expected' => custom_resources.keys).action(:clean)
        end

        if managed?(data['resource_adapters'])
          run_context.task('resource_adapter_cleaner', 'expected' => resource_adapters.keys).action(:clean)
        end

        if managed?(data['jdbc_connection_pools'])
          run_context.task('jdbc_connection_pool_cleaner', 'expected' => jdbc_connection_pools.keys).action(:clean)
        end

        if managed?(data['managed_scheduled_executor_services'])
          run_context.task('managed_scheduled_executor_service_cleaner',
                           'expected' => managed_scheduled_executor_services.keys).
            action(:clean)
        end

        if managed?(data['managed_executor_services'])
          run_context.task('managed_executor_service_cleaner',
                           'expected' => managed_executor_services.keys).
            action(:clean)
        end

        if managed?(data['managed_thread_factories'])
          run_context.task('managed_thread_factory_cleaner', 'expected' => managed_thread_factories.keys).action(:clean)
        end

        if managed?(data['context_services'])
          run_context.task('context_service_cleaner', 'expected' => context_services.keys).action(:clean)
        end

        restart_domain_if_required(run_context, domain_options)

        unless interpret_options['diff_on_completion'].to_s == 'false'
          run_context.task('property_cache',
                           'banner' => 'End of Converge Property Diff',
                           'error_on_differences' => interpret_options['error_on_differences'].to_s == 'true').
            action(:diff)
        end
        run_context.task('property_cache').action(:destroy)

        if managed?(data['domain'])
          run_context.task('domain', domain_options).action(:complete)
        end
      end

      private

      def restart_domain_if_required(run_context, domain_options)
        run_context.task('domain', domain_options).action(:restart_if_required)
      end

      def interpret_system_facilities(run_context, data, domain_options)
        interpret_jvm_options(run_context, data['jvm_options'] || {})
        restart_domain_if_required(run_context, domain_options)

        if managed?(data['logging'])
          interpret_logging(run_context, data['logging'] || {})
          restart_domain_if_required(run_context, domain_options)
        end

        run_context.task('property_cache').action(:create)

        interpret_system_properties(run_context, managed?(data['system_properties']), data['system_properties'] || {})

        libraries = psort(data['libraries'])
        libraries.values.each do |config|
          interpret_library(run_context, config)
        end
        restart_domain_if_required(run_context, domain_options.merge(:context_only => true))

        interpret_realm_types(run_context, data['realm_types'] || {})
        restart_domain_if_required(run_context, domain_options.merge(:context_only => true))

        thread_pools = psort(data['thread_pools'])
        thread_pools.each_pair do |key, config|
          interpret_thread_pool(run_context, key, config)
        end
        restart_domain_if_required(run_context, domain_options)

        iiop_listeners = psort(data['iiop_listeners'])
        iiop_listeners.each_pair do |key, config|
          interpret_iiop_listener(run_context, key, config)
        end

        auth_realms = psort(data['auth_realms'])
        auth_realms.each_pair do |key, config|
          interpret_auth_realm(run_context, key, config)
        end
        restart_domain_if_required(run_context, domain_options)

        jms_hosts = psort(data['jms_hosts'])
        jms_hosts.each_pair do |key, config|
          interpret_jms_hosts(run_context, key, config)
        end

        psort(data['properties']).each_pair do |key, config|
          interpret_property(run_context, key, config)
        end

        if managed?(data['auth_realms'])
          run_context.task('auth_realm_cleaner', 'expected' => auth_realms.keys).action(:clean)
        end

        if managed?(data['jms_hosts'])
          run_context.task('jms_host_cleaner', 'expected' => jms_hosts.keys).action(:clean)
        end

        if managed?(data['iiop_listeners'])
          run_context.task('iiop_listener_cleaner', 'expected' => iiop_listeners.keys).action(:clean)
        end

        if managed?(data['thread_pools'])
          run_context.task('thread_pool_cleaner', 'expected' => thread_pools.keys).action(:clean)
        end

        restart_domain_if_required(run_context, domain_options.merge(:context_only => true))

        if managed?(data['libraries'])
          Redfish::Tasks::Glassfish::Library::LIBRARY_TYPES.each do |library_type|
            expected = libraries.values.collect { |v| v['file'] }
            run_context.task('library_cleaner', 'library_type' => library_type, 'expected' => expected).action(:clean)
          end
        end

        restart_domain_if_required(run_context, domain_options)
      end

      def managed?(data)
        (data.nil? || data['managed'].nil?) ? true : !!data['managed']
      end

      def domain_options(domain_data)
        options = {}

        options['template'] = domain_data['template'] if domain_data['template']
        options['max_mx_wait_time'] = domain_data['max_mx_wait_time'] if domain_data['max_mx_wait_time']
        options['shutdown_on_complete'] = domain_data['shutdown_on_complete'] if domain_data['shutdown_on_complete']
        options['common_name'] = domain_data['common_name'] if domain_data['common_name']
        options['properties'] = domain_data['properties'].dup if domain_data['properties']

        options
      end

      def interpret_jvm_options(run_context, config)
        return unless (config['managed'].nil? ? true : !!config['managed'])

        options = config['options'] || []
        defines = config['defines'] || {}
        default_defines = config['default_defines'].nil? ? true : config['default_defines']
        run_context.task('jvm_options',
                         'jvm_options' => options,
                         'defines' => defines,
                         'default_defines' => default_defines).
          action(:set)
      end

      def interpret_logging(run_context, config)
        if managed?(config['levels'])
          default_levels = config['default_levels'].nil? ? true : config['default_levels']
          interpret_log_levels(run_context, default_levels, config['levels'] || {})
        end

        if managed?(config['attributes'])
          default_attributes = config['default_attributes'].nil? ? true : config['default_attributes']
          interpret_log_attributes(run_context, default_attributes, config['attributes'])
        end
      end

      def interpret_log_levels(run_context, default_levels, config)
        run_context.task('log_levels', 'levels' => psort(config), 'default_levels' => default_levels).action(:set)
      end

      def interpret_log_attributes(run_context, default_attributes, config)
        run_context.task('log_attributes', 'default_attributes' => default_attributes, 'attributes' => psort(config)).action(:set)
      end

      def interpret_system_properties(run_context, managed, config)
        run_context.task('system_properties',
                         'delete_unknown_properties' => managed,
                         'properties' => psort(config)).
          action(:set)
      end

      def interpret_realm_types(run_context, realm_types)
        if managed?(realm_types)
          include_defaults = realm_types['default_realm_types'].nil? ? true : !!realm_types['default_realm_types']
          run_context.task('realm_types',
                           'realm_types' => realm_types['modules'] || {},
                           'default_realm_types' => include_defaults).
            action(:set)
        end
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
        options = config.is_a?(Hash) ? config : {'value' => config}
        run_context.task('property', {'name' => key}.merge(options)).action(:set)
      end

      def interpret_auth_realm(run_context, key, config)
        params = config.dup
        params.delete('users')

        run_context.task('auth_realm', params(params).merge('name' => key)).action(:create)

        if 'com.sun.enterprise.security.auth.realm.file.FileRealm' == params(params)['classname']
          users = psort(config['users'])
          users.each_pair do |username, user_config|
            interpret_file_realm_user(run_context, key, username, user_config)
          end

          if managed?(config['users'])
            run_context.task('file_user_cleaner',
                             'realm_name' => key,
                             'expected' => users.keys).
              action(:clean)
          end
        end
      end

      def interpret_file_realm_user(run_context, auth_realm_key, username, config)
        run_context.task('file_user',
                         params(config).merge('username' => username, 'realm_name' => auth_realm_key)).
          action(:create)
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

        resources = psort(config['resources'])
        resources.each_pair do |resource_key, resource_config|
          interpret_jdbc_resource(run_context, key, resource_key, resource_config)
        end
        if managed?(config['resources'])
          run_context.task('jdbc_resource_cleaner',
                           'connectionpoolid' => key,
                           'expected' => resources.keys).
            action(:clean)
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

        connection_pools = psort(config['connection_pools'])
        connection_pools.each_pair do |pool_key, pool_config|
          interpret_connector_connection_pool(run_context, key, pool_key, pool_config)
        end

        if managed?(config['connection_pools'])
          run_context.task('connector_connection_pool_cleaner',
                           'resource_adapter_name' => key,
                           'expected' => connection_pools.keys).
            action(:clean)
        end

        admin_objects = psort(config['admin_objects'])
        admin_objects.each_pair do |admin_object_key, admin_object_config|
          interpret_admin_object(run_context, key, admin_object_key, admin_object_config)
        end

        if managed?(config['admin_objects'])
          expected = admin_objects.keys
          if 'jmsra' == key
            #TODO: Add admin_objects that result from jms_resource section
          end
          run_context.task('admin_object_cleaner',
                           'resource_adapter_name' => key,
                           'expected' => expected).
            action(:clean)
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

        resources = psort(config['resources'])
        resources.each_pair do |resource_key, resource_config|
          interpret_connector_resource(run_context, key, resource_key, resource_config)
        end

        if managed?(config['resources'])
          run_context.task('connector_resource_cleaner',
                           'connector_pool_name' => key,
                           'expected' => resources.keys).
            action(:clean)
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
        web_env_entries = psort(config['web_env_entries'])
        web_env_entries.each_pair do |entry_key, entry_config|
          run_context.task('web_env_entry', params(entry_config).merge('application' => key, 'name' => entry_key)).action(:create)
        end
        if managed?(config['web_env_entries'])
          run_context.task('web_env_entry_cleaner', {'application' => key, 'expected' => web_env_entries.keys}).action(:clean)
        end
      end

      def params(config)
        params = config.nil? ? {} : config.dup
        params.delete('priority')
        params
      end

      def psort(hash)
        return {} if hash.nil?
        hash = hash.dup
        hash.delete_if { |k, v| k =~ /^_.*/ || k == 'managed' }
        Hash[hash.sort_by { |key, value| "#{'%04d' % priority_value(value)}#{key}" }]
      end

      def priority_value(value)
        value.is_a?(Hash) && value['priority'] ? value['priority'] : 100
      end
    end
  end
end
