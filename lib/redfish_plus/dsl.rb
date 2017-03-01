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

# noinspection RubyClassMethodNamingConvention
# noinspection SpellCheckingInspection
# noinspection RubyStringKeysInHashInspection
module RedfishPlus
  # noinspection RubySimplifyBooleanInspection
  class << self

    def setup_for_docker(domain, options = {})
      # Assume docker is for production, and thus tune it so
      features = options[:features] || []
      domain.package = false
      domain.local = false
      domain.dockerize = true

      common_domain_setup(domain)
      set_jsp_caching(domain, true)

      if features.include?(:jms)
        setup_jms_host(domain, 'REMOTE')
      else
        disable_jms_service(domain)
      end

      if features.include?(:jms) || features.include?(:jdbc)
        setup_orb_to_support_resource_adapter(domain)
      end
    end

    def setup_default_logging(domain)
      set_log_level(domain, 'javax.enterprise.system.container.web.com.sun.web.security.level', 'OFF')
      disable_noisy_database_logging(domain)
    end

    def all_features
      [:jms, :jdbc]
    end

    def configure_local_mail_port(domain)
      domain.data['javamail_resources']["#{::Reality::Naming.underscore(domain.name)}/mail/session"]['properties']['mail.smtp.port'] = '10025'
    end

    def setup_for_local_development(domain, options = {})
      features = options[:features] || all_features
      domain.package = false

      base_setup_for_local_development(domain)

      common_domain_setup(domain)

      if features.include?(:jms)
        setup_jms_host(domain, 'LOCAL')
      else
        disable_jms_service(domain)
      end

      if features.include?(:jms) || features.include?(:jdbc)
        setup_orb_to_support_resource_adapter(domain)
      end

      domain.data['jvm_options']['options'] << '-ea' << '-da:org.glassfish.common.util...'
    end

    def common_domain_setup(domain)
      setup_standard_jvm_options(domain)
      standard_domain_setup(domain)
      setup_http_thread_pool(domain)
      configure_rest_container(domain)
      configure_web_container(domain)
      add_default_concurrency_resources(domain)
      # Temporarily comment this out until differences are elimintated.
      #force_unexpected_differences_to_cause_failure(domain)
      setup_default_logging(domain)
      shutdown_on_complete(domain)
    end

    def setup_http_thread_pool(domain)
      add_thread_pool(domain, 'http-thread-pool', 5, 200)
      set(domain, 'configs.config.server-config.network-config.protocols.protocol.http-listener-1.http.xpowered-by', 'false')
    end

    def base_setup_for_local_development(domain)
      domain.admin_password = nil
      domain.secure = false
      set_idea_compatible_debug_settings(domain)
      mark_applications_as_not_managed(domain)
    end

    def disable_jms_service(domain)
      domain.data['jms_hosts'].clear
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.type', 'DISABLED')
    end

    def setup_jms_host(domain, service_type)
      environment_variable(domain, 'OPENMQ_HOST', '127.0.0.1')
      environment_variable(domain, 'OPENMQ_PORT', '7676')
      environment_variable(domain, 'OPENMQ_ADMIN_USERNAME', 'admin')
      environment_variable(domain, 'OPENMQ_ADMIN_PASSWORD', 'admin')

      jms_host(domain, 'DefaultJmsHost', '${OPENMQ_HOST}', '${OPENMQ_PORT}', '${OPENMQ_ADMIN_USERNAME}', '${OPENMQ_ADMIN_PASSWORD}')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.default-jms-host', 'DefaultJmsHost')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.type', service_type)
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.addresslist-behavior', 'random')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.addresslist-iterations', '3')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.init-timeout-in-seconds', '60')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.reconnect-attempts', '3')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.reconnect-enabled', 'true')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.reconnect-interval-in-seconds', '5')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.reconnect-interval-in-seconds', '5')

      # Assume at this stage that if jms_host is configured then it is for mdb container
      configure_mdb_container(domain)
    end

    def configure_mdb_container(domain)
      set(domain, 'configs.config.server-config.mdb-container.idle-timeout-in-seconds', '600')
      set(domain, 'configs.config.server-config.mdb-container.max-pool-size', '32')
      set(domain, 'configs.config.server-config.mdb-container.pool-resize-quantity', '8')
      set(domain, 'configs.config.server-config.mdb-container.steady-pool-size', '0')
    end

    def configure_rest_container(domain)
      set(domain, 'configs.config.server-config.rest-config.debug', 'false')
      set(domain, 'configs.config.server-config.rest-config.indent-level', '-1')
      set(domain, 'configs.config.server-config.rest-config.log-input', 'false')
      set(domain, 'configs.config.server-config.rest-config.log-output', 'false')
      set(domain, 'configs.config.server-config.rest-config.session-token-timeout', '30')
      set(domain, 'configs.config.server-config.rest-config.show-deprecated-items', 'false')
      set(domain, 'configs.config.server-config.rest-config.show-hidden-commands', 'false')
      set(domain, 'configs.config.server-config.rest-config.wadl-generation', 'false')
    end

    def configure_web_container(domain)
      set(domain, 'configs.config.server-config.web-container.session-config.session-properties.timeout-in-seconds', '1800')
      set(domain, 'configs.config.server-config.web-container.session-config.session-manager.manager-properties.max-sessions', '-1')
      set(domain, 'configs.config.server-config.web-container.session-config.session-manager.manager-properties.reap-interval-in-seconds', '60')
      set_jsp_caching(domain, false)
    end

    def set_jsp_caching(domain, value)
      set(domain, 'configs.config.server-config.web-container.jsp-caching-enabled', value.to_s)
    end

    # Orb required to use Resource adapters for MDBs and JDBC connection pools
    def setup_orb_to_support_resource_adapter(domain)
      # Orb can not share a thread pool with http
      add_thread_pool(domain, 'orb-thread-pool', 5, 150)
      set_orb_thread_pool(domain, 'orb-thread-pool')
      add_dummy_iiop_listener(domain)
    end

    def add_default_concurrency_resources(domain)
      # This should not be used but as Payara/GlassFish will recreate them on
      # restart, we create them to avoid having them recreated
      add_default_context_service(domain)
      add_default_managed_thread_factory(domain)
      add_default_managed_executor_service(domain)
      add_default_managed_scheduled_executor_service(domain)
    end

    def add_default_context_service(domain)
      add_context_service(domain, 'concurrent/__defaultContextService', 'enabled' => 'false')
    end

    def add_context_service(domain, name, options = {})
      domain.data['context_services'][name]['enabled'] = options['enabled'] || 'true'
      domain.data['context_services'][name]['context_info_enabled'] = 'true'
      domain.data['context_services'][name]['context_info'] = 'Classloader,JNDI,Security,WorkArea'
      domain.data['context_services'][name]['deployment_order'] = 100
      options.each_pair do |key, value|
        domain.data['context_services'][name][key] = value
      end
    end

    def add_default_managed_thread_factory(domain)
      add_managed_thread_factory(domain, 'concurrent/__defaultManagedThreadFactory', 'enabled' => 'false')
    end

    def add_managed_thread_factory(domain, name, options = {})
      domain.data['managed_thread_factories'][name]['enabled'] = options['enabled'] || 'true'
      domain.data['managed_thread_factories'][name]['context_info_enabled'] = 'true'
      domain.data['managed_thread_factories'][name]['context_info'] = 'Classloader,JNDI,Security,WorkArea'
      domain.data['managed_thread_factories'][name]['deployment_order'] = 100
      domain.data['managed_thread_factories'][name]['thread_priority'] = 5
      options.each_pair do |key, value|
        domain.data['managed_thread_factories'][name][key] = value
      end
    end

    def add_default_managed_executor_service(domain)
      add_managed_executor_service(domain,
                                   'concurrent/__defaultManagedExecutorService',
                                   'enabled' => 'false',
                                   'long_running_tasks' => 'false',
                                   'hung_after_seconds' => '1',
                                   'core_pool_size' => '0',
                                   'maximum_pool_size' => '1',
                                   'keep_alive_seconds' => '1',
                                   'thread_lifetime_seconds' => '1',
                                   'task_queue_capacity' => '1')
    end

    def add_managed_executor_service(domain, name, options = {})
      domain.data['managed_executor_services'][name]['enabled'] = options['enabled'] || 'true'
      domain.data['managed_executor_services'][name]['context_info_enabled'] = 'true'
      domain.data['managed_executor_services'][name]['context_info'] = 'Classloader,JNDI,Security,WorkArea'
      domain.data['managed_executor_services'][name]['deployment_order'] = 100
      domain.data['managed_executor_services'][name]['thread_priority'] = 5
      options.each_pair do |key, value|
        domain.data['managed_executor_services'][name][key] = value
      end
    end

    def add_default_managed_scheduled_executor_service(domain)
      add_managed_scheduled_executor_service(domain,
                                             'concurrent/__defaultManagedScheduledExecutorService',
                                             'enabled' => 'false',
                                             'long_running_tasks' => 'false',
                                             'hung_after_seconds' => '1',
                                             'core_pool_size' => '0',
                                             'keep_alive_seconds' => '1',
                                             'thread_lifetime_seconds' => '1')
    end

    def add_managed_scheduled_executor_service(domain, name, options = {})
      domain.data['managed_scheduled_executor_services'][name]['enabled'] = options['enabled'] || 'true'
      domain.data['managed_scheduled_executor_services'][name]['context_info_enabled'] = 'true'
      domain.data['managed_scheduled_executor_services'][name]['context_info'] = 'Classloader,JNDI,Security,WorkArea'
      domain.data['managed_scheduled_executor_services'][name]['deployment_order'] = 100
      domain.data['managed_scheduled_executor_services'][name]['thread_priority'] = 5
      options.each_pair do |key, value|
        domain.data['managed_scheduled_executor_services'][name][key] = value
      end
    end

    # Standard configuration used across all of our GlassFish instances
    def standard_domain_setup(domain)
      set_payara_domain_template(domain)
      set_user_prefs_dir(domain)
      set_tmpdir(domain)
      disable_update_tool(domain)
      enable_implicit_cdi(domain)
      setup_default_admin(domain)
      add_default_file_realm(domain, 'file')
      set_default_auth_realm(domain, 'file')
      disable_classloading_delegation(domain)
      disable_autodeploy(domain)
      disable_dynamic_reload(domain)
      disable_non_portable_jndi_names(domain)
      domain.ports << 8080
    end

    def setup_standard_jvm_options(domain, min_memory = '2g', max_memory = '2g', max_stack_size = '350k')
      domain.data['jvm_options']['options'] = %W(-XX:NewRatio=2 -Xss#{max_stack_size} -Xms#{min_memory} -Xmx#{max_memory} -server -XX:+UnlockDiagnosticVMOptions -XX:+UseG1GC -XX:+UseStringDeduplication)
    end

    def shutdown_on_complete(domain)
      domain.data['domain']['shutdown_on_complete'] = 'true'
    end

    def mark_applications_as_not_managed(domain)
      domain.data['applications']['managed'] = false
    end

    def add_library_from_path(domain, name, path, require_restart = false, library_type = 'common')
      domain.file(name, path)
      add_library(domain, name, "{{file:#{name}}}", require_restart, library_type)
    end

    def add_library(domain, name, file, require_restart = false, library_type = 'common')
      domain.data['libraries'][name]['file'] = file
      domain.data['libraries'][name]['require_restart'] = require_restart
      domain.data['libraries'][name]['library_type'] = library_type
    end

    def deploy_application(domain, name, context_root, location)
      domain.data['applications'][name]['context_root'] = context_root
      domain.data['applications'][name]['location'] = location
    end

    def system_property(domain, key, value)
      domain.data['system_properties'][key] = value
    end

    def set_appserver_domain_template(domain)
      set_standard_domain_template(domain, 'appserver')
    end

    def set_nucleus_domain_template(domain)
      set_standard_domain_template(domain, 'nucleus')
    end

    def set_payara_domain_template(domain)
      set_standard_domain_template(domain, 'payara')
    end

    def set_standard_domain_template(domain, key)
      set_domain_template(domain, "{{glassfish_home}}/glassfish/common/templates/gf/#{key}-domain.jar")
    end

    def set_domain_template(domain, template)
      domain.data['domain']['template'] = template
    end

    def add_file_realm(domain, name, file)
      add_realm(domain,
                name,
                'com.sun.enterprise.security.auth.realm.file.FileRealm',
                'jaas-context' => 'fileRealm',
                'file' => file)
    end

    def add_realm(domain, name, classname, properties)
      domain.data['auth_realms'][name]['classname'] = classname
      properties.each_pair do |k, v|
        domain.data['auth_realms'][name]['properties'][k] = v
      end
    end

    def add_file_realm_user(domain, realm_name, username, password, groups = [])
      domain.data['auth_realms'][realm_name]['users'][username]['password'] = password
      domain.data['auth_realms'][realm_name]['users'][username]['groups'] = groups
    end

    def setup_default_admin(domain)
      add_default_admin_realm(domain)
      add_admin_thread_pool(domain)
    end

    def add_default_admin_realm(domain)
      add_file_realm(domain, 'admin-realm', '${com.sun.aas.instanceRoot}/config/admin-keyfile')
      add_file_realm_user(domain, 'admin-realm', domain.admin_username, domain.admin_password, ['asadmin'])
    end

    # Usually required unless the default realm has been changed
    def add_default_file_realm(domain, realm)
      add_file_realm(domain, realm, '${com.sun.aas.instanceRoot}/config/keyfile')
    end

    def set_default_auth_realm(domain, realm)
      set(domain, 'configs.config.server-config.security-service.default-realm', realm)
    end

    def add_admin_thread_pool(domain, min = 5, max = 15, options = {'maxqueuesize' => 256})
      add_thread_pool(domain, 'admin-thread-pool', min, max, options)
    end

    def add_thread_pool(domain, name, min, max, options = {})
      domain.data['thread_pools'][name]['minthreadpoolsize'] = min
      domain.data['thread_pools'][name]['maxthreadpoolsize'] = max
      options.each_pair do |k, v|
        domain.data['thread_pools'][name][k.to_s] = v
      end
    end

    def set_user_prefs_dir(domain)
      domain.data['jvm_options']['defines']['java.util.prefs.userRoot'] = '{{domain_directory}}/prefs'
    end

    def set_tmpdir(domain)
      domain.data['jvm_options']['defines']['java.io.tmpdir'] = '{{domain_directory}}/tmp'
    end

    def disable_update_tool(domain)
      domain.data['jvm_options']['defines']['com.sun.enterprise.tools.admingui.NO_NETWORK'] = 'true'
    end

    def environment_variable(domain, key, value = 'UNSPECIFIED', default_value = '')
      system_property(domain, key, value)
      domain.data['environment_vars'][key] = default_value
    end

    def volume_requirement(domain, key)
      domain.data['volumes'][key]
    end

    def force_unexpected_differences_to_cause_failure(domain)
      domain.data['config']['error_on_differences'] = true
    end

    def disable_non_portable_jndi_names(domain)
      set(domain, 'configs.config.server-config.ejb-container.property.disable-nonportable-jndi-names', 'true')
    end

    def disable_dynamic_reload(domain)
      set(domain, 'configs.config.server-config.admin-service.das-config.dynamic-reload-enabled', 'false')
    end

    def disable_autodeploy(domain)
      set(domain, 'configs.config.server-config.admin-service.das-config.autodeploy-enabled', 'false')
    end

    def disable_classloading_delegation(domain)
      domain.data['jvm_options']['defines']['fish.payara.classloading.delegate'] = 'false'
    end

    def set(domain, key, value)
      domain.data['properties'][key] = value
    end

    def set_and_require_restart(domain, key, value)
      domain.data['properties'][key]['require_restart'] = 'true'
      domain.data['properties'][key]['value'] = value
    end

    def set_idea_compatible_debug_settings(domain)
      set(domain, 'configs.config.server-config.java-config.debug-enabled', 'false')
      set(domain, 'configs.config.server-config.java-config.debug-options', '-agentlib:jdwp=transport=dt_socket,address=43228,server=n,suspend=y')
    end

    def enable_implicit_cdi(domain)
      domain.data['properties']['configs.config.server-config.cdi-service.enable-implicit-cdi'] = 'true'
    end

    # The JMS subsystem seems to require iiop listener be initialized before it starts up. As we do not use iiop
    # we create a dummy listener that should never get used
    def add_dummy_iiop_listener(domain)
      domain.data['iiop_listeners']['unused_iiop_listener']['address'] = '127.0.0.1'
      domain.data['iiop_listeners']['unused_iiop_listener']['port'] = '11235'
      domain.data['iiop_listeners']['unused_iiop_listener']['enabled'] = false
      domain.data['iiop_listeners']['unused_iiop_listener']['securityenabled'] = false
    end

    # We must set the orbs thread pool even if not used otherwise the orb will not start
    def set_orb_thread_pool(domain, thread_pool_id)
      set(domain, 'configs.config.server-config.iiop-service.orb.use-thread-pool-ids', thread_pool_id)
    end

    def disable_noisy_database_logging(domain)
      set_log_level(domain, 'javax.enterprise.resource.resourceadapter.com.sun.gjc.spi', 'WARNING')
      set_log_level(domain, 'javax.enterprise.resource.jta', 'OFF')
    end

    def set_log_level(domain, key, level)
      domain.data['logging']['levels'][key] = level
    end

    def custom_resource(domain, name, value, restype = nil)
      domain.data['custom_resources'][name]['properties']['value'] = value
      domain.data['custom_resources'][name]['restype'] = restype if restype
    end

    def custom_resource_from_env(domain, name, env_key = nil, restype = nil, default_value = nil)
      components = name.split('/')
      components = [components.first] + components[2..components.size] if components.size > 2 && components[1] == 'env'
      env_key = components.join('_').upcase if env_key.nil?
      custom_resource(domain, name, "${#{env_key}}", restype)
      environment_variable(domain, env_key, 'UNSPECIFIED', default_value)
    end

    def replicant_client_config(domain, host_application, replicant_application)
      prefix = "#{host_application}/replicant/client/#{replicant_application}"
      custom_resource_from_env(domain, "#{prefix}/url")
      custom_resource_from_env(domain, "#{prefix}/repositoryDebugOutputEnabled", nil, 'java.lang.Boolean', 'false')
      custom_resource_from_env(domain, "#{prefix}/subscriptionsDebugOutputEnabled", nil, 'java.lang.Boolean', 'false')
      custom_resource_from_env(domain, "#{prefix}/shouldValidateRepositoryOnLoad", nil, 'java.lang.Boolean', 'false')
      custom_resource_from_env(domain, "#{prefix}/requestDebugOutputEnabled", nil, 'java.lang.Boolean', 'false')
      add_managed_scheduled_executor_service(domain, "#{prefix}/ManagedScheduledExecutorService")
    end

    def jms_connection_factory(domain, name)
      domain.data['jms_resources'][name]['restype'] = 'javax.jms.ConnectionFactory'
    end

    def jms_destination(domain, name, physical_name, is_queue)
      domain.data['jms_resources'][name]['restype'] = is_queue ? 'javax.jms.Queue' : 'javax.jms.Topic'
      domain.data['jms_resources'][name]['properties']['Name'] = physical_name
    end

    def jms_queue(domain, name, physical_name)
      jms_destination(domain, name, physical_name, true)
    end

    def jms_topic(domain, name, physical_name)
      jms_destination(domain, name, physical_name, false)
    end

    def jms_host(domain, name, host, port, admin_username, admin_password)
      domain.data['jms_hosts'][name]['host'] = host
      domain.data['jms_hosts'][name]['port'] = port
      domain.data['jms_hosts'][name]['admin_username'] = admin_username
      domain.data['jms_hosts'][name]['admin_password'] = admin_password
    end

    def mssql_jdbc_resource(domain, name, resource_name)
      connection_pool = "#{resource_name}ConnectionPool"

      domain.data['jdbc_connection_pools'][connection_pool]['datasourceclassname'] = 'net.sourceforge.jtds.jdbcx.JtdsDataSource'
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['AppName'] = domain.name
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['ProgName'] = 'GlassFish'
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['SocketTimeout'] = '1200'
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['LoginTimeout'] = '60'
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['SocketKeepAlive'] = 'true'

      # This next lines is required for jtds drivers as still old driver style
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['jdbc30DataSource'] = 'true'

      jdbc_resource(domain, name, resource_name)
    end

    def pgsql_jdbc_resource(domain, name, resource_name)
      connection_pool = "#{resource_name}ConnectionPool"

      domain.data['jdbc_connection_pools'][connection_pool]['datasourceclassname'] = 'org.postgresql.ds.PGSimpleDataSource'

      jdbc_resource(domain, name, resource_name)
    end

    def jdbc_resource(domain, name, resource_name)
      constant_prefix = ::Reality::Naming.uppercase_constantize(domain.name)
      cname = ::Reality::Naming.uppercase_constantize(name)
      prefix = cname == constant_prefix ? constant_prefix : "#{constant_prefix}_#{cname}"

      connection_pool = "#{resource_name}ConnectionPool"
      domain.data['jdbc_connection_pools'][connection_pool]['restype'] = 'javax.sql.DataSource'
      domain.data['jdbc_connection_pools'][connection_pool]['isconnectvalidatereq'] = 'true'
      domain.data['jdbc_connection_pools'][connection_pool]['validationmethod'] = 'auto-commit'
      domain.data['jdbc_connection_pools'][connection_pool]['ping'] = 'true'
      domain.data['jdbc_connection_pools'][connection_pool]['description'] = "#{resource_name} connection pool for application #{domain.name}"
      domain.data['jdbc_connection_pools'][connection_pool]['resources'][resource_name]['description'] = "#{resource_name} resource for application #{domain.name}"

      domain.data['environment_vars']["#{prefix}_DB_HOST"] = nil
      domain.data['environment_vars']["#{prefix}_DB_PORT"] = nil
      domain.data['environment_vars']["#{prefix}_DB_DATABASE"] = nil
      domain.data['environment_vars']["#{prefix}_DB_USERNAME"] = domain.name
      domain.data['environment_vars']["#{prefix}_DB_PASSWORD"] = nil

      domain.data['jdbc_connection_pools'][connection_pool]['properties']['ServerName'] = "${#{prefix}_DB_HOST}"
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['PortNumber'] = "${#{prefix}_DB_PORT}"
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['DatabaseName'] = "${#{prefix}_DB_DATABASE}"
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['User'] = "${#{prefix}_DB_USERNAME}"
      domain.data['jdbc_connection_pools'][connection_pool]['properties']['Password'] = "${#{prefix}_DB_PASSWORD}"
    end

    def javamail_resource(domain, resource_name, options = {})
      key = options[:key] || domain.name
      constant_prefix = ::Reality::Naming.uppercase_constantize(domain.name)
      cname = ::Reality::Naming.uppercase_constantize(key)
      prefix = cname == constant_prefix ? constant_prefix : "#{constant_prefix}_#{cname}"

      domain.data['environment_vars']["#{prefix}_MAIL_HOST"] = nil
      domain.data['environment_vars']["#{prefix}_MAIL_USER"] = nil
      domain.data['environment_vars']["#{prefix}_MAIL_FROM"] = nil

      domain.data['javamail_resources'][resource_name]['host'] = "${#{prefix}_MAIL_HOST}"
      domain.data['javamail_resources'][resource_name]['user'] = "${#{prefix}_MAIL_USER}"
      domain.data['javamail_resources'][resource_name]['from'] = "${#{prefix}_MAIL_FROM}"
    end
  end
end
