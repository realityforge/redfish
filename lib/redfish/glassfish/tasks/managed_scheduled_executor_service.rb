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
      class ManagedScheduledExecutorService < BaseResourceTask
        PROPERTY_PREFIX = 'resources.managed-scheduled-executor-service.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true

        # Determines whether the resource is enabled at runtime.
        attribute :enabled, :type => :boolean, :default => true
        # Determines whether container contexts are propagated to threads. If set to true, the contexts specified in the --contextinfo option are propagated. If set to false, no contexts are propagated and the --contextinfo option is ignored.
        attribute :context_info_enabled, :type => :boolean, :default => true
        # Specifies individual container contexts to propagate to threads. Valid values are Classloader, JNDI, Security, and WorkArea. Values are specified in a comma-separated list and are case-insensitive. All contexts are propagated by default.
        attribute :context_info, :kind_of => String, :default => 'Classloader,JNDI,Security,WorkArea'
        # Specifies the priority to assign to created threads.
        attribute :thread_priority, :type => :integer, :default => 5
        # Specifies whether the resource should be used for long-running tasks. If set to true, long-running tasks are not reported as stuck.
        attribute :long_running_tasks, :type => :boolean, :default => false
        # Specifies the number of seconds that a task can execute before it is considered unresponsive. If the value is 0 tasks are never considered unresponsive.
        attribute :hung_after_seconds, :type => :integer, :default => 0
        # Specifies the number of threads to keep in a thread pool, even if they are idle.
        attribute :core_pool_size, :type => :integer, :default => 0
        # Specifies the number of seconds that threads can remain idle when the number of threads is greater than corepoolsize.
        attribute :keep_alive_seconds, :type => :integer, :default => 60
        # Specifies the number of seconds that threads can remain in a thread pool before being purged, regardless of whether the number of threads is greater than corepoolsize or whether the threads are idle. The value of 0 means that threads are never purged.
        attribute :thread_lifetime_seconds, :type => :integer, :default => 0

        # Descriptive details about the resource.
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        action :create do
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['description'] = self.description
          property_map['context-info-enabled'] = self.context_info_enabled
          property_map['context-info'] = self.context_info
          property_map['enabled'] = self.enabled
          property_map['thread-priority'] = self.thread_priority
          property_map['core-pool-size'] = self.core_pool_size
          property_map['hung-after-seconds'] = self.hung_after_seconds
          property_map['keep-alive-seconds'] = self.keep_alive_seconds
          property_map['long-running-tasks'] = self.long_running_tasks
          property_map['thread-lifetime-seconds'] = self.thread_lifetime_seconds

          property_map
        end

        def do_create
          args = []

          args << '--enabled' << self.enabled.to_s
          args << '--contextinfoenabled' << self.context_info_enabled.to_s
          args << '--contextinfo' << self.context_info.to_s
          args << '--threadpriority' << self.thread_priority.to_s
          args << '--corepoolsize' << self.core_pool_size.to_s
          args << '--hungafterseconds' << self.hung_after_seconds.to_s
          args << '--keepaliveseconds' << self.keep_alive_seconds.to_s
          args << '--longrunningtasks' << self.long_running_tasks.to_s
          args << '--threadlifetimeseconds' << self.thread_lifetime_seconds.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description.to_s
          args << self.name.to_s

          context.exec('create-managed-scheduled-executor-service', args)
        end

        def do_destroy
          context.exec('delete-managed-scheduled-executor-service', [self.name])
        end

        def present?
          (context.exec('list-managed-scheduled-executor-services', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
