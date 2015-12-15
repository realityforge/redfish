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

module Redfish #nodoc

  # Record contains task and action run as well as the metrics and outputs of running action
  class TaskExecutionRecord
    attr_reader :task
    attr_reader :action_started_at
    attr_reader :action_finished_at
    attr_reader :action_error

    def initialize(task)
      @task = task
      @action = nil
      @action_started_at = nil
      @action_finished_at = nil
      @action_performed_update = false
      @action_error = nil
    end

    def converge
      task.run_context.converge_task(self)
    end

    def action(action = nil)
      raise "Attempting to retrieve action for #{task} when no action defined" if action.nil? && @action.nil?
      raise "Attempting to write action for #{task} when action already defined as #{@action.inspect}" if !action.nil? && !@action.nil?
      @action = action if action
      @action
    end

    def action_started?
      !@action_started_at.nil?
    end

    def action_finished?
      !@action_finished_at.nil?
    end

    def action_started_at=(time)
      raise 'action_started_at invoked after action started' unless @action_started_at.nil?
      @action_started_at = time
    end

    def action_finished_at=(time)
      raise 'action_finished_at= invoked before action started' if @action_started_at.nil?
      raise 'action_finished_at= invoked after action finished' unless @action_finished_at.nil?
      @action_finished_at = time
    end

    def action_performed_update?
      raise 'action_performed_update? invoked before action started' if @action_started_at.nil?
      raise 'action_performed_update? invoked before action finished' if @action_finished_at.nil?
      @action_performed_update
    end

    def action_error=(action_error)
      raise 'action_error= invoked before action started' if @action_started_at.nil?
      raise 'action_error= invoked after action started' unless @action_finished_at.nil?
      @action_error = action_error
    end

    def action_error?
      raise 'action_error? invoked before action started' if @action_started_at.nil?
      raise 'action_error? invoked before action finished' if @action_finished_at.nil?
      !!@action_error
    end

    def action_performed_update!
      raise 'action_performed_update! invoked before action started' if @action_started_at.nil?
      raise 'action_performed_update! invoked after action finished' unless @action_finished_at.nil?
      @action_performed_update = true
    end

    def to_s
      "#{task}.#{@action}"
    end
  end
end
