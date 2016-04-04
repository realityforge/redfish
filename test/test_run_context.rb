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

class Redfish::TestRunContext < Redfish::TestCase
  def test_basic_interaction
    run_context = Redfish::RunContext.new(create_simple_context(Redfish::Executor.new))

    assert_equal run_context.execution_records.size, 0

    run_context.task('property', 'name' => 'myKey', 'value' => 'myValue').action(:set)

    assert_equal run_context.execution_records.size, 1
  end
end
