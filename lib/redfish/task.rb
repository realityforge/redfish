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
  module MetaDataHelper
    def self.included(base)
      class << base
        def action(key, &block)
          define_method("perform_#{key}") do
            instance_eval(&block)
          end
        end

        def attribute(key, options)
          unexpected_keys = options.keys - [:kind_of, :equal_to, :regex, :required, :default]
          raise "Unknown keys passed to attribute method: #{unexpected_keys.inspect}" unless unexpected_keys.empty?

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

  class Task < Redfish::BaseElement
    def Task.inherited(mod)
      TaskManager.register_task(mod)
    end

    def Task.mark_as_abstract!
      TaskManager.mark_as_abstract!(self)
    end

    class << self
      def registered_name
        Redfish::Naming.underscore(name.split('::').last)
      end
    end

    include MetaDataHelper

    attr_writer :context

    def initialize(options = {})
      super(options)
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
