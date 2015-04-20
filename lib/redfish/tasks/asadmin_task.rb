module Redfish
  module Tasks
    class AsadminTask < Redfish::Task

      self.mark_as_abstract!

      protected

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
