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

require File.expand_path('../helper', __FILE__)

class Redfish::TestTaskExecutionRecord < Redfish::TestCase

  def test_basic_interaction
    fake_task = 'MyTask'
    record = Redfish::TaskExecutionRecord.new(fake_task)

    assert_equal record.task, fake_task

    assert_equal record.action_started?, false
    assert_equal record.action_finished?, false

    # action not yet set
    assert_raise(RuntimeError) { record.action }

    record.action(:myaction)
    assert_equal record.action, :myaction

    # Should not be able to override action
    assert_raise(RuntimeError) { record.action(:myaction) }

    # Should not be able to do following until started
    assert_raise(RuntimeError) { record.action_error = 'X' }
    assert_raise(RuntimeError) { record.action_performed_update! }
    assert_raise(RuntimeError) { record.action_error? }
    assert_raise(RuntimeError) { record.action_performed_update? }

    record.action_started_at = Time.now

    assert_equal record.action_started?, true
    assert_equal record.action_finished?, false

    record.action_error = 'X'
    record.action_performed_update!
    assert_raise(RuntimeError) { record.action_error? }
    assert_raise(RuntimeError) { record.action_performed_update? }

    record.action_finished_at = Time.now

    assert_equal record.action_started?, true
    assert_equal record.action_finished?, true

    assert_raise(RuntimeError) { record.action_error = 'X' }
    assert_raise(RuntimeError) { record.action_performed_update! }

    assert_equal record.action_error?, true
    assert_equal record.action_performed_update?, true
  end
end
