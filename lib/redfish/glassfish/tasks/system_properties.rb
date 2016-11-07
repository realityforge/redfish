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
      class SystemProperties < AsadminTask
        PROPERTY_PREFIX = 'servers.server.server.system-property.'

        private

        attribute :properties, :kind_of => Hash, :default => {}
        # Specifies whether the unknown properties should be deleted.
        attribute :delete_unknown_properties, :type => :boolean, :default => true

        action :set do
          existing = current_properties
          expected = properties.dup

          tocreate = {}
          expected.each do |k, v|
            tocreate[k] = v unless existing[k] == v
          end

          todelete = []
          existing.keys.each do |k|
            todelete << k unless expected[k]
          end if self.delete_unknown_properties

          unless todelete.empty? && tocreate.empty?
            todelete.each do |key|
              context.exec('delete-system-property', [key])
              context.property_cache.delete_all_with_prefix!("#{PROPERTY_PREFIX}#{key}.") if context.property_cache?
            end
            context.exec('create-system-properties', [encode_parameters(tocreate)]) unless tocreate.empty?

            expected.each do |k, v|
              context.property_cache["#{PROPERTY_PREFIX}#{k}.name"] = k
              context.property_cache["#{PROPERTY_PREFIX}#{k}.value"] = as_property_value(v)
            end if context.property_cache?

            updated_by_last_action
          end
        end

        def instance_key
          "properties=#{properties.inspect}"
        end

        def current_properties
          properties = {}
          cache_present = context.property_cache?

          if cache_present
            context.property_cache.get_keys_starting_with(PROPERTY_PREFIX).each do |key|
              next unless key =~ /.*\.value$/
              property_name = key[PROPERTY_PREFIX.size...-6]
              properties[property_name] = context.property_cache[key]
            end
          else
            context.exec('list-system-properties', [], :terse => true, :echo => false).split("\n").each do |line|
              next if line == 'Nothing to list.'
              next if line =~ /^The target server contains following.*/
              index = line.index('=')
              key = line[0, index]
              value = line[index + 1, line.size]
              properties[key] = value
            end
          end
          properties
        end
      end
    end
  end
end
