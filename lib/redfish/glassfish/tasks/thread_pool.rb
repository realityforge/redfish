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
      class ThreadPool < BaseResourceTask
        PROPERTY_PREFIX = 'configs.config.server-config.thread-pools.thread-pool.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        # Specifies the minimum number of threads in the pool. These are created when the thread pool is instantiated.
        attribute :minthreadpoolsize, :type => :integer, :default => 2
        # Specifies the maximum number of threads the pool can contain.
        attribute :maxthreadpoolsize, :type => :integer, :default => 5
        # Specifies the amount of time in seconds after which idle threads are removed from the pool.
        attribute :idletimeout, :type => :integer, :default => 900
        # Specifies the maximum number of messages that can be queued until threads are available to process them for a network listener or IIOP listener. A value of -1 specifies no limit.
        attribute :maxqueuesize, :type => :integer, :default => 4096

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
          {'name' => self.name}
        end

        def properties_to_set_in_create
          property_map = {}

          property_map['idle-thread-timeout-seconds'] = self.idletimeout
          property_map['max-thread-pool-size'] = self.maxthreadpoolsize
          property_map['min-thread-pool-size'] = self.minthreadpoolsize
          property_map['max-queue-size'] = self.maxqueuesize
          property_map['classname'] = 'org.glassfish.grizzly.threadpool.GrizzlyExecutorService'

          property_map
        end

        def do_create
          args = []

          args << '--maxthreadpoolsize' << self.maxthreadpoolsize.to_s
          args << '--minthreadpoolsize' << self.minthreadpoolsize.to_s
          args << '--idletimeout' << self.idletimeout.to_s
          args << '--maxqueuesize' << self.maxqueuesize.to_s
          args << self.name.to_s

          context.exec('create-threadpool', args)
        end

        def do_destroy
          context.exec('delete-threadpool', [self.name])
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-threadpools', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
