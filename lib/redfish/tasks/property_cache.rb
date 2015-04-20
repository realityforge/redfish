module Redfish
  module Tasks
    class PropertyCache < AsadminTask

      private

      action :create do
        output = context.exec('get', %w(*), :terse => true, :echo => false)

        properties = {}
        output.split("\n").each do |line|
          index = line.index('=')
          key = line[0, index]
          value = line[index + 1, line.size]
          properties[key] = value
        end

        skip = false
        if context.property_cache?
          if context.property_cache.properties != properties
            context.remove_property_cache
          else
            skip = true
          end
        end

        unless skip
          context.cache_properties(properties)
          updated_by_last_action
        end
      end

      action :destroy do
        if context.property_cache?
          context.remove_property_cache
          updated_by_last_action
        end
      end
    end
  end
end
