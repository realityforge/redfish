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

class Redfish::TestConfig < Redfish::TestCase

  def test_default_glassfish_home
    ENV['GLASSFISH_HOME'] = nil

    assert_raise(RuntimeError, "Unable to determine default_glassfish_home, GLASSFISH_HOME environment variable not specified. Please specify using Redfish::Config.default_glassfish_home = '/path/to/glassfish'") { Redfish::Config.default_glassfish_home }

    assert_equal Redfish::CAPTURE.string, "Unable to determine default_glassfish_home, GLASSFISH_HOME environment variable not specified. Please specify using Redfish::Config.default_glassfish_home = '/path/to/glassfish'\n"

    ENV['GLASSFISH_HOME'] = 'X'
    begin
      assert_equal Redfish::Config.default_glassfish_home, 'X'
    ensure
      ENV['GLASSFISH_HOME'] = nil
    end

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal Redfish::Config.default_glassfish_home, 'Y'
  end

  def test_task_prefix
    assert_equal Redfish::Config.task_prefix, 'redfish'
    Redfish::Config.task_prefix = 'Y'
    assert_equal Redfish::Config.task_prefix, 'Y'
    Redfish::Config.task_prefix = nil
    assert_equal Redfish::Config.task_prefix, 'redfish'
  end

  def test_default_domains_directory
    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal Redfish::Config.default_domains_directory, 'Y/glassfish/domains'

    Redfish::Config.default_domains_directory = 'X/domains'

    assert_equal Redfish::Config.default_domains_directory, 'X/domains'

    Redfish::Config.default_domains_directory = nil

    assert_equal Redfish::Config.default_domains_directory, 'Y/glassfish/domains'

    ENV['GLASSFISH_DOMAINS_DIR'] = '/srv/domains'
    assert_equal Redfish::Config.default_domains_directory, '/srv/domains'
  end

  def test_default_domain_key
    assert_raise(RuntimeError, "Unable to determine default_domain_key. Please specify using Redfish::Config.default_domain_key = 'myapp'") { Redfish::Config.default_domain_key }
    assert_equal Redfish::CAPTURE.string, "Unable to determine default_domain_key. Please specify using Redfish::Config.default_domain_key = 'myapp'\n"
    assert_equal Redfish::Config.default_domain_key?('myapp'), false

    Redfish::Config.default_domain_key = 'myapp'
    assert_equal Redfish::Config.default_domain_key?('myapp'), true
    assert_equal Redfish::Config.default_domain_key?(:myapp), true
  end

  def test_base_directory
    assert_equal Redfish::Config.base_directory, '.'
    Redfish::Config.base_directory = 'X'
    assert_equal Redfish::Config.base_directory, 'X'
    Redfish::Config.base_directory = nil
    assert_equal Redfish::Config.base_directory, '.'
  end
end
