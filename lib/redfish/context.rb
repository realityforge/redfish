module Redfish
  class Context
    # The name of the domain.
    attr_reader :domain_name
    # The port on which the management application is bound.
    attr_reader :domain_admin_port
    # If true use SSL when communicating with the domain for administration. Assumes the domain is in secure mode.
    attr_reader :domain_secure
    # The username to use when communicating with the domain.
    attr_reader :domain_username
    # The password file used when connecting to glassfish.
    attr_reader :domain_password_file

    # Use terse output from the underlying asadmin.
    def terse?
      !!@terse
    end

    #If true, echo commands supplied to asadmin.
    def echo?
      !!@echo
    end

    # The user that the domain executes as.
    attr_reader :system_user
    # The group that the domain executes as.
    attr_reader :system_group

    def initialize(domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file, options = {})
      @domain_name, @domain_admin_port, @domain_secure, @domain_username, @domain_password_file =
        domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file
      @echo = options[:echo].nil? ? false : !!options[:echo]
      @terse = options[:terse].nil? ? false : !!options[:terse]
      @system_user = options[:system_user]
      @system_group = options[:system_group]
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
