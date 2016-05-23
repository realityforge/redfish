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

class Redfish::TestDefinition < Redfish::TestCase

  def test_basic_workflow
    definition = Redfish::DomainDefinition.new('appserver')

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal definition.name, 'appserver'
    assert definition.data.is_a?(Redfish::Mash)
    assert_equal definition.secure?, true
    assert_equal definition.port, 4848
    assert_equal definition.admin_username, 'admin'
    assert_equal definition.admin_password.size, 10
    assert_equal definition.glassfish_home, 'Y'
    assert_equal definition.domains_directory, 'Y/glassfish/domains'

    definition.secure = false
    definition.port = 8080
    definition.admin_username = 'bob'
    definition.admin_password = 'secret'
    definition.glassfish_home = '/usr/local/glassfish'
    definition.domains_directory = '/srv/glassfish/appserver'

    assert_equal definition.secure?, false
    assert_equal definition.port, 8080
    assert_equal definition.admin_username, 'bob'
    assert_equal definition.admin_password, 'secret'
    assert_equal definition.glassfish_home, '/usr/local/glassfish'
    assert_equal definition.domains_directory, '/srv/glassfish/appserver'

    context = definition.to_task_context

    assert_equal context.domain_name, 'appserver'
    assert_equal context.domain_admin_port, 8080
    assert_equal context.domain_secure, false
    assert_equal context.domain_username, 'bob'
    assert_equal context.domain_password, 'secret'
  end
end
