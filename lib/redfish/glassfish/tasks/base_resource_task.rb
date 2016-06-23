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
                record_reference if add_resource_ref?
              end
            end
          end

          unless create_occurred
            set_properties(property_prefix, properties_to_set_in_create)
          end

          set_properties(property_prefix, properties_to_always_set)

          set_deployment_order(property_prefix)

          if create_occurred
            post_create_hook
          end
        end

        def record_reference
          record_properties_in_cache('',
                                     "servers.server.server.resource-ref.#{resource_name}.enabled" => true,
                                     "servers.server.server.resource-ref.#{resource_name}.ref" => resource_name)
        end

        def resource_name
          self.name
        end

        def add_resource_ref?
          true
        end

        def post_create_hook
        end

        def record_properties_in_cache(property_prefix, props)
          props.each_pair do |k, v|
            context.property_cache["#{property_prefix}#{k}"] = as_property_value(v)
          end
        end

        def set_properties(property_prefix, property_map)
          i = immutable_local_properties
          property_map.each_pair do |key, value|
            t = run_context.task('property', 'name' => "#{property_prefix}#{key}", 'value' => as_property_value(value))
            if i.include?(key)
              begin
                t.action(:ensure)
                run_context.converge_task(t)
              rescue
                message = "Immutable property '#{property_prefix}#{key}' is different from the expected value '#{as_property_value(value)}'."
                Redfish.warn(message)
                raise message
              end
            else
              t.action(:set)
              run_context.converge_task(t)
            end
            updated_by_last_action if t.task.updated_by_last_action?
          end
        end

        def set_deployment_order(property_prefix)
          if self.respond_to?(:deployment_order)
            t = run_context.task('property', 'name' => "#{property_prefix}deployment-order", 'value' => self.deployment_order.to_s)
            t.action(:set)
            run_context.converge_task(t)
            updated_by_last_action if t.task.updated_by_last_action?
          end
        end

        def destroy(property_prefix)
          cache_present = context.property_cache?
          may_need_delete = cache_present ? context.property_cache.any_property_start_with?(property_prefix) : true

          if may_need_delete
            if cache_present || present?

              ensure_resource_deleteable(property_prefix)

              do_destroy

              updated_by_last_action

              if cache_present
                context.property_cache.delete_all_with_prefix!(property_prefix)
                remove_reference if add_resource_ref?
              end
            end
          end
        end

        def remove_reference
          context.property_cache.delete_all_with_prefix!("servers.server.server.resource-ref.#{resource_name}.")
        end

        def ensure_resource_deleteable(property_prefix)
          if context.property_cache? && context.property_cache["#{property_prefix}object-type"] == 'system-all-req'
            t = run_context.task('property', 'name' => "#{property_prefix}object-type", 'value' => 'system-all')
            t.action(:set)
            run_context.converge_task(t)
          end
        end

        def immutable_local_properties
          []
        end

        def properties_to_record_in_create
          raise 'properties_to_record_in_create unimplemented'
        end

        def properties_to_always_set
          {}
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
end
