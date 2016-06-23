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
      class PropertyCache < AsadminTask
        private

        attribute :banner, :kind_of => String
        attribute :error_on_differences, :type => :boolean, :default => false

        action :create do
          do_create
        end

        action :create_unless_present do
          do_create unless context.property_cache?
        end

        action :diff do
          if context.property_cache?
            properties = load_properties('*')

            lines = []

            context.property_cache.properties.keys.sort.each do |key|
              value1 = context.property_cache.properties[key]
              value2 = properties.delete(key)
              if value1.to_s != value2.to_s
                lines << "- #{key}=#{value1}"
                lines << "+ #{key}=#{value2}"
              end
            end
            properties.each_pair do |key, value|
              lines << "+ #{key}=#{value}"
            end

            if lines.size > 0
              output("#{self.banner}\n-------------------\n") if self.banner

              lines.each do |line|
                output(line)
              end

              output("\n-------------------\n") if self.banner

              updated_by_last_action
              if self.error_on_differences
                raise 'Unexpected differences when error_on_differences property set results in an error'
              end
            end
          end
        end

        action :destroy do
          if context.property_cache?
            context.remove_property_cache
            updated_by_last_action
          end
        end

        def output(message)
          puts message
        end

        def do_create
          properties = load_properties('*')

          skip = false
          if context.property_cache?
            if context.property_cache.properties != properties
              context.remove_property_cache
            else
              skip = true
            end
          end

          unless skip
            context.cache_properties(properties)
            updated_by_last_action
          end
        end
      end
    end
  end
end
