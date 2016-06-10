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
  class << self

    def setup_for_docker(domain, options = {})
      features = options[:features] || []
      domain.package = false
      domain.local = false
      domain.dockerize = true

      common_domain_setup(domain)

      if features.include?(:jms)
        setup_jms_host(domain, 'REMOTE')
      else
        disable_jms_service(domain)
      end
    end

    def setup_default_logging(domain)
      set_log_level(domain, 'javax.enterprise.system.container.web.com.sun.web.security.level', 'OFF')
      disable_noisy_database_logging(domain)
    end

    def setup_for_local_development(domain, options = {})
      features = options[:features] || []
      domain.package = false

      common_domain_setup(domain)

      base_setup_for_local_development(domain)
      if features.include?(:jms)
        setup_jms_host(domain, 'EMBEDDED')
      else
        disable_jms_service(domain)
      end
    end

    def common_domain_setup(domain)
      setup_standard_jvm_options(domain)
      standard_domain_setup(domain)
      setup_http_thread_pool(domain)
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

      setup_orb_to_support_jms(domain)
      jms_host(domain, 'DefaultJmsHost', '${OPENMQ_HOST}', '${OPENMQ_PORT}', '${OPENMQ_ADMIN_USERNAME}', '${OPENMQ_ADMIN_PASSWORD}')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.default-jms-host', 'DefaultJmsHost')
      set_and_require_restart(domain, 'configs.config.server-config.jms-service.type', service_type)
      set(domain, 'configs.config.server-config.jms-service.addresslist-behavior', 'random')
      set(domain, 'configs.config.server-config.jms-service.addresslist-iterations', '3')
      set(domain, 'configs.config.server-config.jms-service.init-timeout-in-seconds', '60')
      set(domain, 'configs.config.server-config.jms-service.reconnect-attempts', '3')
      set(domain, 'configs.config.server-config.jms-service.reconnect-enabled', 'true')
      set(domain, 'configs.config.server-config.jms-service.reconnect-interval-in-seconds', '5')
      set(domain, 'configs.config.server-config.jms-service.reconnect-interval-in-seconds', '5')

      # Assume at this stage that if jms_host is configured then it is for mdb container
      configure_mdb_container(domain)
    end

    def configure_mdb_container(domain)
      set(domain, 'configs.config.server-config.mdb-container.idle-timeout-in-seconds', '600')
      set(domain, 'configs.config.server-config.mdb-container.max-pool-size', '32')
      set(domain, 'configs.config.server-config.mdb-container.pool-resize-quantity', '8')
      set(domain, 'configs.config.server-config.mdb-container.steady-pool-size', '0')
    end

    # Orb required to use MDBs due to feature/bugs of GlassFish/Payara
    def setup_orb_to_support_jms(domain)
      # Orb can not share a thread pool with http
      add_thread_pool(domain, 'orb-thread-pool', 1, 1)
      set_orb_thread_pool(domain, 'orb-thread-pool')
      add_dummy_iiop_listener(domain)
    end

    # Standard configuration used across all of our GlassFish instances
    def standard_domain_setup(domain)
      set_payara_domain_template(domain)
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

    def setup_standard_jvm_options(domain, min_memory = '2048m', max_memory = '2048m', max_perm_size = '512m', max_stack_size = '350k')
      domain.data['jvm_options']['options'] = %W(-XX:NewRatio=2 -Xss#{max_stack_size} -Xms#{min_memory} -Xmx#{max_memory} -XX:MaxPermSize=#{max_perm_size} -server -XX:+UnlockDiagnosticVMOptions)
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
      domain.data['auth_realms'][name]['classname'] = 'com.sun.enterprise.security.auth.realm.file.FileRealm'
      domain.data['auth_realms'][name]['properties']['jaas-context'] = 'fileRealm'
      domain.data['auth_realms'][name]['properties']['file'] = file
    end

    def setup_default_admin(domain)
      add_default_admin_realm(domain)
      add_admin_thread_pool(domain)
    end

    def add_default_admin_realm(domain)
      add_file_realm(domain, 'admin-realm', '${com.sun.aas.instanceRoot}/config/admin-keyfile')
    end

    # Usually required unless the default realm has been changed
    def add_default_file_realm(domain, realm)
      add_file_realm(domain, realm, '${com.sun.aas.instanceRoot}/config/keyfile')
    end

    def set_default_auth_realm(domain, realm)
      set(domain, 'configs.config.server-config.security-service.auth-realm.file.name', realm)
    end

    def add_admin_thread_pool(domain, min = 5, max = 50, options = {'maxqueuesize' => 256})
      add_thread_pool(domain, 'admin-thread-pool', min, max, options)
    end

    def add_thread_pool(domain, name, min, max, options = {})
      domain.data['thread_pools'][name]['minthreadpoolsize'] = min
      domain.data['thread_pools'][name]['maxthreadpoolsize'] = max
      options.each_pair do |k, v|
        domain.data['thread_pools'][name][k.to_s] = v
      end
    end

    def disable_update_tool(domain)
      domain.data['jvm_options']['defines']['com.sun.enterprise.tools.admingui.NO_NETWORK'] = 'true'
    end

    def environment_variable(domain, key, value = 'UNSPECIFIED', default_value = '')
      system_property(domain, key, value)
      domain.environment_vars[key] = default_value
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

    def custom_resource(domain, name, value)
      domain.data['custom_resources'][name]['properties']['value'] = value
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
  end
end
