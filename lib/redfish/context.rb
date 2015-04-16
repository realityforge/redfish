module Redfish
  class Context
    attr_reader :domain_name
    attr_reader :domain_admin_port
    attr_reader :domain_secure
    attr_reader :domain_username
    attr_reader :domain_password_file

    def initialize(domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file)
      @domain_name, @domain_admin_port, @domain_secure, @domain_username, @domain_password_file =
        domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file
      @property_cache = nil
    end

    def property_cache?
      !@property_cache.nil?
    end

    def property_cache
      raise 'Property cache not defined' unless property_cache?
      @property_cache
    end

    def cache_properties(properties)
      raise 'Property cache already defined' if property_cache?
      @property_cache = PropertyCache.new(properties)
    end
  end
end
