module Redfish
  module Tasks
    class BaseResourceTask < AsadminTask

      self.mark_as_abstract!

      protected

      def create(property_prefix)
        cache_present = context.property_cache?
        may_need_create = cache_present ? !context.property_cache.any_property_start_with?(property_prefix) : true

        create_occurred = false

        if may_need_create
          if cache_present || !present?
            do_create
            updated_by_last_action

            create_occurred = true

            if cache_present
              record_properties_in_cache(property_prefix, properties_to_set_in_create)
              record_properties_in_cache(property_prefix, properties_to_record_in_create)
            end
          end
        end

        unless create_occurred
          set_properties(property_prefix, properties_to_set_in_create)
        end

        set_deployment_order(property_prefix)
      end

      def record_properties_in_cache(property_prefix, props)
        props.each_pair do |k, v|
          context.property_cache["#{property_prefix}#{k}"] = as_property_value(v)
        end
      end

      def set_properties(property_prefix, property_map)
        property_map.each_pair do |key, value|
          t = context.task('property', 'key' => "#{property_prefix}#{key}", 'value' => as_property_value(value))
          t.perform_action(:set)
          updated_by_last_action if t.updated_by_last_action?
        end
      end

      def set_deployment_order(property_prefix)
        if self.respond_to?(:deploymentorder)
          t = context.task('property', 'key' => "#{property_prefix}deployment-order", 'value' => self.deploymentorder.to_s)
          t.perform_action(:set)
          updated_by_last_action if t.updated_by_last_action?
        end
      end

      def destroy(property_prefix)
        cache_present = context.property_cache?
        may_need_delete = cache_present ? context.property_cache.any_property_start_with?(property_prefix) : true

        if may_need_delete
          if cache_present || present?

            do_destroy

            updated_by_last_action

            if cache_present
              context.property_cache.delete_all_with_prefix!(property_prefix)
            end
          end
        end
      end

      def properties_to_record_in_create
        raise 'properties_to_record_in_create unimplemented'
      end

      def properties_to_set_in_create
        raise 'properties_to_set_in_create unimplemented'
      end

      def do_create
        raise 'do_create unimplemented'
      end

      def do_destroy
        raise 'do_destroy unimplemented'
      end

      def present?
        raise 'present? unimplemented'
      end
    end
  end
end
