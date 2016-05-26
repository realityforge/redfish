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
  class Driver
    class << self
      # Given definition and options, setup a run context and converge domain
      def configure_domain(definition, options = {})
        run_context = Redfish::RunContext.new(definition.to_task_context)

        (options[:listeners] || []).each do |listener|
          run_context.listeners << listener
        end

        Redfish::Interpreter.interpret(run_context, definition.resolved_data.to_h)

        run_context.converge

        run_context
      end
    end
  end
end
