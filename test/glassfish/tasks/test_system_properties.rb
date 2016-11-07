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

require File.expand_path('../../../helper', __FILE__)

class Redfish::Tasks::Glassfish::TestSystemProperties < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_set
    data = {'system_properties' => {'managed' => true, 'X' => 'Y', 'P' => 'Q'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor,
                              context,
                              "servers.server.server.system-property.X.name=X\n" +
                                "servers.server.server.system-property.X.value=Y\n" +
                                "servers.server.server.system-property.A.name=A\n" +
                                "servers.server.server.system-property.A.value=B" +
                                "servers.server.server.system-property.G.name=G\n" +
                                "servers.server.server.system-property.G.value=GV")

    executor.expects(:exec).with(equals(context),
                                 equals('delete-system-property'),
                                 equals(%w(A)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('delete-system-property'),
                                 equals(%w(G)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('create-system-properties'),
                                 equals(%w(P=Q)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :set)
  end

  def test_interpret_set_when_matches
    data = {'system_properties' => {'managed' => true, 'X' => 'Y'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, "servers.server.server.system-property.X.name=X\nservers.server.server.system-property.X.value=Y")

    perform_interpret(context, data, false, :set)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.properties = {'A' => 'B:1'}

    assert_equal t.to_s, 'system_properties[properties={"A"=>"B:1"}]'
  end

  def test_set_when_attributes_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('servers.server.server.system-property.X.name' => 'X',
                               'servers.server.server.system-property.X.value' => 'Y',
                               'servers.server.server.system-property.A.name' => 'A',
                               'servers.server.server.system-property.A.value' => 'B',
                               'servers.server.server.system-property.G.name' => 'G',
                               'servers.server.server.system-property.G.value' => 'GV')
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-system-property'),
                                 equals(%w(A)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-system-property'),
                                 equals(%w(G)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-system-properties'),
                                 equals(%w(P=Q)),
                                 equals({})).
      returns('')

    t.properties = {'X' => 'Y', 'P' => 'Q'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)

    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.X.')
    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.P.')
    assert !t.context.property_cache.any_property_start_with?('servers.server.server.system-property.A.')
    assert !t.context.property_cache.any_property_start_with?('servers.server.server.system-property.G.')
  end

  def test_set_when_attributes_no_match_but_delete_unknown_properties_is_false
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('servers.server.server.system-property.X.name' => 'X',
                               'servers.server.server.system-property.X.value' => 'Y',
                               'servers.server.server.system-property.A.name' => 'A',
                               'servers.server.server.system-property.A.value' => 'B',
                               'servers.server.server.system-property.G.name' => 'G',
                               'servers.server.server.system-property.G.value' => 'GV')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-system-properties'),
                                 equals(%w(P=Q)),
                                 equals({})).
      returns('')

    t.properties = {'X' => 'Y', 'P' => 'Q'}
    t.delete_unknown_properties = false
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)

    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.X.')
    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.P.')
    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.A.')
    assert t.context.property_cache.any_property_start_with?('servers.server.server.system-property.G.')
  end

  def test_set_when_attributes_no_match_and_no_property_cache
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-system-properties'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("The target server contains following 3 system properties\nX=Y\nA=B\nG=GV\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-system-property'),
                                 equals(%w(A)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-system-property'),
                                 equals(%w(G)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-system-properties'),
                                 equals(%w(P=Q)),
                                 equals({})).
      returns('')

    t.properties = {'X' => 'Y', 'P' => 'Q'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end
end
