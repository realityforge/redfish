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
      class AsadminTask < Redfish::Task

        self.mark_as_abstract!

        protected

        # Return a struct representing the domain version
        def domain_version
          context.property_cache? ?
            context.domain_version :
            context.domain_version(get_property('domain.version'))
        end

        #
        # Many glassfish resources have an "extensible" set of properties with declared under the resource.
        # This method assumes there is a method "properties" that returns a list of said properties. It then
        # adds each these properties to a map with name relative to the resource. It also adds empty properties
        # to the map for any properties that need to be removed.
        #
        # e.g.
        #    collect_property_sets('resources.jdbc-connection-pool.MyDbPool.', property_map)
        #
        def collect_property_sets(property_prefix, property_map, properties = self.properties)
          properties.each_pair do |key, value|
            property_map["property.#{key}"] = as_property_value(value)
          end

          full_prefix = "#{property_prefix}property."

          extra_property_keys =
            context.property_cache? ?
              context.property_cache.get_keys_starting_with(full_prefix) :
              load_properties("#{full_prefix}*").keys

          properties.keys.each do |k|
            extra_property_keys.delete("#{full_prefix}#{k}")
          end

          extra_property_keys.each do |key|
            k = key[full_prefix.length..-1]
            property_map["property.#{k}"] = ''
          end
        end

        def reload_properties_with_prefix(prefix)
          context.property_cache.delete_all_with_prefix!(prefix)

          properties = load_properties("#{prefix}*")
          properties.each do |k, v|
            context.property_cache[k] = v
          end
        end

        def reload_property(key)
          context.property_cache[key] = load_property(key)
        end

        def load_properties(pattern, options = {})
          output = context.exec('get', [pattern], {:terse => true, :echo => false}.merge(options))
          parse_properties(output)
        end

        def load_property(key, options = {})
          result = load_properties(key, options)
          result.empty? ? nil : result.values[0]
        end

        def get_property(key, options = {})
          context.property_cache? ? context.property_cache[key] : load_property(key, options)
        end

        def parse_properties(output)
          properties = {}
          output.split("\n").each do |line|
            index = line.index('=')
            key = line[0, index]
            value = line[index + 1, line.size]
            properties[key] = value
          end
          properties
        end

        def as_property_value(value)
          value.nil? ? '' : value.to_s
        end

        def encode_options(options)
          "#{options.collect { |v| escape_property(v) }.join(':')}"
        end

        def encode_parameters(properties)
          "#{properties.collect { |k, v| "#{k}=#{escape_property(v)}" }.join(':')}"
        end

        def escape_property(string)
          string.to_s.gsub(/([#{Regexp.escape('+\/,=:.!$%^&*|{}[]"`~;')}])/) { |match| "\\#{match}" }
        end

        def updated_by_last_action
          context.require_restart! if self.respond_to?(:require_restart) && self.require_restart
          super
        end
      end
    end
  end
end
