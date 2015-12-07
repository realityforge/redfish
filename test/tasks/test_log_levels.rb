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

require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestLogLevels < Redfish::Tasks::BaseTaskTest
  def test_interpret_set
    data = {'log_levels' => {'iris' => 'WARNING', 'iris.planner' => 'INFO'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    mock_property_get(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('set-log-levels'),
                                 equals(%w(iris=WARNING:iris.planner=INFO)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :set, 0)
  end

  def test_interpret_set_when_matches
    data = {'log_levels' => {'iris' => 'WARNING', 'iris.planner' => 'INFO'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    mock_property_get(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<WARNING>\niris.planner\t<INFO>\njavax\t<SEVERE>")

    perform_interpret(context, data, false, :set, 0)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}

    assert_equal t.to_s, 'log_levels[iris=WARNING,iris.planner=INFO]'
  end

  def test_set_when_levels_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-levels'),
                                 equals(%w(iris=WARNING:iris.planner=INFO)),
                                 equals({})).
      returns('')

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_levels_partially_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<SEVERE>\niris.planner\t<INFO>\njavax\t<SEVERE>\niris.acal\t<INFO>")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-levels'),
                                 equals(%w(iris=WARNING:iris.acal=WARNING)),
                                 equals({})).
      returns('')

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO', 'iris.acal' => 'WARNING'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_levels_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<WARNING>\niris.planner\t<INFO>\njavax\t<SEVERE>")

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end
end
