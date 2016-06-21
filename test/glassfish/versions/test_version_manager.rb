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

class Redfish::Versions::TestVersionManager < Redfish::TestCase
  def test_basic_operation
    initial_count = Redfish::VersionManager.versions.size
    assert_equal Redfish::VersionManager.version_by_version_key?('bob'), false
    error = false
    begin
      Redfish::VersionManager.version_by_version_key('bob')
    rescue
      error = true
    end
    assert_equal error, true

    Redfish::VersionManager.register_version(Redfish::Versions::BaseVersion.new('bob', :payara, '4.1.1.bob'))

    assert_equal Redfish::VersionManager.versions.size, initial_count + 1
    assert_equal Redfish::VersionManager.version_by_version_key?('bob'), true
    version = Redfish::VersionManager.version_by_version_key('bob')
    assert_not_nil version
    assert_equal version.version, '4.1.1.bob'
    assert_equal version.variant, :payara
    assert_equal version.payara?, true
    assert_equal version.glassfish?, false
  end
end
