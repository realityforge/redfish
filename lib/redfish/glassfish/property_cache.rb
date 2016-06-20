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
  class PropertyCache

    def initialize(properties)
      @properties = properties.dup
    end

    def any_property_start_with?(prefix)
      regex = prefix_regex(prefix)
      raw_properties.keys.any? { |k| k =~ regex }
    end

    def get_keys_starting_with(prefix)
      regex = prefix_regex(prefix)
      raw_properties.keys.select { |k| k =~ regex }
    end

    def delete_all_with_prefix!(prefix)
      regex = prefix_regex(prefix)
      raw_properties.keys.each do |k|
        raw_properties.delete(k) if k =~ regex
      end
    end

    def []=(key, value)
      raw_properties[key] = value
    end

    def [](key)
      raw_properties[key] || ''
    end

    def properties
      raw_properties.dup
    end

    private

    def prefix_regex(prefix)
      /^#{Regexp.escape(prefix)}/
    end

    def raw_properties
      @properties
    end
  end
end
