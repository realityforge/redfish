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
        raise "Attempting to configure domain '#{definition.name}' using and incomplete domain definition '#{definition.key}'" unless definition.complete?
        task_context = definition.to_task_context
        run_context = Redfish::RunContext.new(task_context)

        (options[:listeners] || []).each do |listener|
          run_context.listeners << listener
        end

        data = definition.resolved_data
        if options[:update_only]
          Redfish::Interpreter::PreInterpreter.mark_as_unmanaged(data)
        end

        Redfish::Interpreter.interpret(run_context, data.to_h)

        begin
          run_context.converge
        rescue Exception => e
          if options[:update_only]
            log_file = "#{task_context.domain_directory}/logs/server.log"
            puts IO.read(log_file).split("\n").last(100).join("\n") if File.exist?(log_file)
          end
          raise e
        end

        run_context
      end
    end
  end
end