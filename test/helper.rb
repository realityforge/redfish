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

$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'mocha/setup'
require 'fileutils'
require 'redfish'
require File.expand_path('../_include2', __FILE__)

class Redfish::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    @temp_dir = nil
  end

  def teardown
    unless @temp_dir.nil?
      FileUtils.rm_rf @temp_dir
      @temp_dir = nil
    end
  end

  def temp_dir
    if @temp_dir.nil?
      base_temp_dir = ENV['TEST_TMP_DIR'] || File.expand_path("#{File.dirname(__FILE__)}/../tmp")
      @temp_dir = "#{base_temp_dir}/redfish-#{Time.now.to_i}"
      FileUtils.mkdir_p @temp_dir
    end
    @temp_dir
  end

  def create_simple_context(executor)
    Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
  end
end

require "#{File.dirname(__FILE__)}/tasks/base_task_test.rb"
