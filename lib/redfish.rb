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

require 'redfish/version'
require 'redfish/naming'
require 'redfish/core'
require 'redfish/property_cache'
require 'redfish/context'
require 'redfish/executor'
require 'redfish/task_manager'
require 'redfish/task'

require 'redfish/tasks/asadmin_task'
require 'redfish/tasks/base_resource_task'
require 'redfish/tasks/property_cache'
require 'redfish/tasks/property'
require 'redfish/tasks/jdbc_connection_pool'
require 'redfish/tasks/jdbc_resource'
require 'redfish/tasks/custom_resource'
require 'redfish/tasks/thread_pool'
require 'redfish/tasks/iiop_listener'
require 'redfish/tasks/javamail_resource'
require 'redfish/tasks/web_env_entry'
require 'redfish/tasks/context_service'
require 'redfish/tasks/managed_thread_factory'
require 'redfish/tasks/managed_executor_service'
require 'redfish/tasks/managed_scheduled_executor_service'
require 'redfish/tasks/auth_realm'
require 'redfish/tasks/connector_connection_pool'
require 'redfish/tasks/connector_resource'
