module Redfish
  class TaskManager
    class << self
      @@task_map = {}
      @@abstract_types = []

      def register_task(type)
        name = Redfish::Naming.underscore(type.name.split('::').last)
        raise "Task already registered with name '#{name}' when attempting to register #{type}" if @@task_map[name]
        Redfish.debug("Registering task '#{name}' with type #{type}")
        @@task_map[name] = type
      end

      def mark_as_abstract!(type)
        @@abstract_types << type
      end

      # Return the set of keys under which tasks are registered
      def registered_task_names
        @@task_map.keys.dup
      end

      def create_task(context, name, options = {})
        type = @@task_map[name]
        raise "No task registered with name '#{name}'" unless type
        raise "Attempted to instantiate abstract task with name '#{name}'" if @@abstract_types.include?(type)
        t = type.new
        t.context = context
        t.options = options
        yield t if block_given?
        t
      end
    end
  end
end
