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

require 'etc'
require 'logger'
require 'tempfile'
require 'json'
require 'digest/md5'

require 'redfish/version'
require 'redfish/naming'
require 'redfish/core'
require 'redfish/mash'
require 'redfish/util'
require 'redfish/config'
require 'redfish/task_manager'
require 'redfish/task'
require 'redfish/task_execution_record'
require 'redfish/listener'
require 'redfish/run_context'

#
# GlassFish specific parts
#

require 'redfish/glassfish/property_cache'
require 'redfish/glassfish/context'
require 'redfish/glassfish/executor'
require 'redfish/glassfish/model'
require 'redfish/glassfish/definition'
require 'redfish/glassfish/driver'
require 'redfish/glassfish/buildr_integration'

require 'redfish/glassfish/interpreter/pre_interpreter'
require 'redfish/glassfish/interpreter/interpolater'
require 'redfish/glassfish/interpreter/interpreter'

require 'redfish/glassfish/versions/version_manager'
require 'redfish/glassfish/versions/payara_154'
require 'redfish/glassfish/versions/payara_162'

require 'redfish/glassfish/tasks/asadmin_task'
require 'redfish/glassfish/tasks/base_cleaner_task'
require 'redfish/glassfish/tasks/base_resource_task'
require 'redfish/glassfish/tasks/property_cache'
require 'redfish/glassfish/tasks/property'
require 'redfish/glassfish/tasks/jdbc_connection_pool'
require 'redfish/glassfish/tasks/jdbc_connection_pool_cleaner'
require 'redfish/glassfish/tasks/jdbc_resource'
require 'redfish/glassfish/tasks/jdbc_resource_cleaner'
require 'redfish/glassfish/tasks/custom_resource'
require 'redfish/glassfish/tasks/custom_resource_cleaner'
require 'redfish/glassfish/tasks/domain'
require 'redfish/glassfish/tasks/file_user'
require 'redfish/glassfish/tasks/file_user_cleaner'
require 'redfish/glassfish/tasks/system_properties'
require 'redfish/glassfish/tasks/thread_pool'
require 'redfish/glassfish/tasks/thread_pool_cleaner'
require 'redfish/glassfish/tasks/iiop_listener'
require 'redfish/glassfish/tasks/iiop_listener_cleaner'
require 'redfish/glassfish/tasks/javamail_resource'
require 'redfish/glassfish/tasks/javamail_resource_cleaner'
require 'redfish/glassfish/tasks/web_env_entry'
require 'redfish/glassfish/tasks/web_env_entry_cleaner'
require 'redfish/glassfish/tasks/context_service'
require 'redfish/glassfish/tasks/context_service_cleaner'
require 'redfish/glassfish/tasks/managed_thread_factory'
require 'redfish/glassfish/tasks/managed_thread_factory_cleaner'
require 'redfish/glassfish/tasks/managed_executor_service'
require 'redfish/glassfish/tasks/managed_executor_service_cleaner'
require 'redfish/glassfish/tasks/managed_scheduled_executor_service'
require 'redfish/glassfish/tasks/managed_scheduled_executor_service_cleaner'
require 'redfish/glassfish/tasks/auth_realm'
require 'redfish/glassfish/tasks/auth_realm_cleaner'
require 'redfish/glassfish/tasks/connector_connection_pool'
require 'redfish/glassfish/tasks/connector_connection_pool_cleaner'
require 'redfish/glassfish/tasks/connector_resource'
require 'redfish/glassfish/tasks/connector_resource_cleaner'
require 'redfish/glassfish/tasks/admin_object'
require 'redfish/glassfish/tasks/admin_object_cleaner'
require 'redfish/glassfish/tasks/resource_adapter'
require 'redfish/glassfish/tasks/resource_adapter_cleaner'
require 'redfish/glassfish/tasks/library'
require 'redfish/glassfish/tasks/library_cleaner'
require 'redfish/glassfish/tasks/log_attributes'
require 'redfish/glassfish/tasks/log_levels'
require 'redfish/glassfish/tasks/jvm_options'
require 'redfish/glassfish/tasks/jms_host'
require 'redfish/glassfish/tasks/jms_host_cleaner'
require 'redfish/glassfish/tasks/jms_resource'
require 'redfish/glassfish/tasks/application'
require 'redfish/glassfish/tasks/application_cleaner'
require 'redfish/glassfish/tasks/realm_types'
