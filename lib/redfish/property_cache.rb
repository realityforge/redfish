module Redfish
  class PropertyCache

    def initialize(properties)
      @properties = properties.dup
    end

    def any_property_start_with?(prefix)
      regex = /^#{Regexp.escape(prefix)}/
      raw_properties.keys.any? { |k| k =~ regex }
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

    def raw_properties
      @properties
    end
  end
end
