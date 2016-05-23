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
    assert_raise(RuntimeError, "Unable to determine default_glassfish_home, GLASSFISH_HOME environment variable not specified. Please specify using Redfish::Config.default_glassfish_home = '/path/to/glassfish'") { Redfish::Config.default_glassfish_home }

    ENV['GLASSFISH_HOME'] = 'X'
    begin
      assert_equal Redfish::Config.default_glassfish_home, 'X'
    ensure
      ENV['GLASSFISH_HOME'] = nil
    end

    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal Redfish::Config.default_glassfish_home, 'Y'
  end

  def test_default_domains_directory
    Redfish::Config.default_glassfish_home = 'Y'
    assert_equal Redfish::Config.default_domains_directory, 'Y/glassfish/domains'

    Redfish::Config.default_domains_directory = 'X/domains'

    assert_equal Redfish::Config.default_domains_directory, 'X/domains'
  end
end
