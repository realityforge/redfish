module Redfish
  class Property < Task

    attribute :key, :kind_of => String, :required => true
    attribute :value, :kind_of => String, :required => true

    private

    action :set do
      cache_present = context.property_cache?
      may_need_update = cache_present ? self.value != context.property_cache[self.key] : true
      if may_need_update
        get_output = context.exec('Asadmin-Property-Set', 'get', ["#{self.key}"], :terse => true, :echo => false)
        unless /^#{Regexp.escape("#{self.key}=#{self.value}")}$/ =~ get_output
          context.exec('Asadmin-Property-Set', 'set', ["#{self.key}=#{self.value}"], :terse => true, :echo => false)
          updated_by_last_action
          if cache_present
            context.property_cache[self.key] = self.value
          end
        end
      end
    end
  end
end
