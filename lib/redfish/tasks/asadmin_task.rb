module Redfish
  module Tasks
    class AsadminTask < Redfish::Task

      self.mark_as_abstract!

      protected

      #
      # Many glassfish resources have an "extensible" set of properties with declared under the resource.
      # This method assumes there is a method "properties" that returns a list of said properties. It then
      # adds each these properties to a map with name relative to the resource. It also adds empty properties
      # to the map for any properties that need to be removed.
      #
      # e.g.
      #    collect_property_sets('resources.jdbc-connection-pool.MyDbPool.', property_map)
      #
      def collect_property_sets(property_prefix, property_map)
        self.properties.each_pair do |key, value|
          property_map["property.#{key}"] = as_property_value(value)
        end

        full_prefix = "#{property_prefix}property."

        extra_property_keys =
          context.property_cache? ?
            context.property_cache.get_keys_starting_with(full_prefix) :
            load_properties("#{full_prefix}*").keys

        self.properties.keys.each do |k|
          extra_property_keys.delete("#{full_prefix}#{k}")
        end

        extra_property_keys.each do |key|
          k = key[full_prefix.length..-1]
          property_map["property.#{k}"] = ''
        end
      end

      def load_properties(pattern)
        output = context.exec('get', [pattern], :terse => true, :echo => false)
        parse_properties(output)
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
    end
  end
end
