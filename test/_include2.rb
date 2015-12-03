require 'mocha/parameter_matchers/all_of'
require 'mocha/parameter_matchers/base'

module Mocha
  module ParameterMatchers
    def includes2(*items)
      Includes2.new(*items)
    end

    class Includes2 < Base
      def initialize(*items)
        @items = items
      end

      def matches?(available_parameters)
        parameter = available_parameters.shift
        return false unless parameter.respond_to?(:include?)

        if @items.size == 1
          @items.first.matches?(parameter)
        else
          includes_matchers = @items.map { |item| Includes2.new(item) }
          AllOf.new(*includes_matchers).matches?([parameter])
        end
      end

      def mocha_inspect
        item_descriptions = @items.map(&:mocha_inspect)
        "includes2(#{item_descriptions.join(', ')})"
      end
    end
  end
end
