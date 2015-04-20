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
