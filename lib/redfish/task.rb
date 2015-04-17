module Redfish
  module MetaDataHelper
    def self.included(base)
      class << base

        def action(key, &block)
          define_method("perform_#{key}") do
            instance_eval(&block)
          end
        end

        def attribute(key, options)
          define_method("#{key}=") do |value|
            kind_of = ([options[:kind_of]] || []).compact.flatten
            if !kind_of.empty? && !kind_of.any? { |k| value.is_a?(k) }
              raise "Invalid value passed to attribute '#{key}' expected to be one of #{kind_of.inspect} but is of type #{value.class.name}"
            end
            equal_to = options[:equal_to] || []
            if !equal_to.empty? && !equal_to.any? { |v| value == v }
              raise "Invalid value passed to attribute '#{key}' expected to be one of #{equal_to.inspect} but is #{value.inspect}"
            end
            regex = options[:regex]
            if regex && !value.nil? && !(regex =~ value.to_s)
              raise "Invalid value passed to attribute '#{key}' expected to match regex #{regex.inspect} but is #{value.inspect}"
            end
            instance_variable_set("@#{key}", value)
          end

          define_method(key) do
            if instance_variable_defined?("@#{key}")
              instance_variable_get("@#{key}")
            elsif !options[:required].nil? && options[:required]
              raise "Required attribute '#{key}' not specified"
            else
              options[:default]
            end
          end
        end
      end
    end
  end

  class Task
    include MetaDataHelper

    attr_writer :context

    def initialize
      @updated_by_last_action = false
      yield self if block_given?
    end

    def context
      raise 'No context associated with task' unless @context
      @context
    end

    def perform_action(action)
      method_name = "perform_#{action}"
      raise "No such action #{action}" unless self.respond_to?(method_name)
      self.send method_name
    end

    def updated_by_last_action?
      !!@updated_by_last_action
    end

    protected

    def updated_by_last_action
      @updated_by_last_action = true
    end
  end
end
