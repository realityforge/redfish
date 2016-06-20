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

module Redfish
  class << self
    def clear_domain_map
      domain_map.clear
    end
  end
end

module Redfish
  CAPTURE = StringIO.new
  remove_const(:Logger)
  Logger = ::Logger.new(CAPTURE)
  Logger.level = ::Logger::INFO
  Logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n"}
end


class Redfish::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    @original_glassfish_home = ENV['GLASSFISH_HOME']
    @original_glassfish_domains_dir = ENV['GLASSFISH_DOMAINS_DIR']
    ENV['GLASSFISH_HOME'] = nil

    Redfish::CAPTURE.reopen('')
    @temp_dir = nil
    Redfish.clear_domain_map
    Redfish::Config.default_glassfish_home = nil
    Redfish::Config.default_domains_directory = nil
    Redfish::Config.task_prefix = nil
    Redfish::Config.default_domain_key = nil
    Redfish::Config.base_directory = nil
  end

  def teardown
    ENV['GLASSFISH_HOME'] = @original_glassfish_home
    ENV['GLASSFISH_DOMAINS_DIR'] = @original_glassfish_domains_dir
    unless @temp_dir.nil?
      FileUtils.rm_rf @temp_dir unless ENV['NO_DELETE_DIR'] == 'true'
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

  def test_domains_dir
    "#{temp_dir}/domains"
  end

  def assert_file_mode(filename, mode)
    assert_equal sprintf('%o', File::Stat.new(filename).mode)[-3, 3], mode
  end

  def create_simple_context(executor = Redfish::Executor.new, options = {})
    Redfish::Context.new(executor,
                         '/opt/payara-4.1.151/',
                         'domain1',
                         4848,
                         false,
                         'admin',
                         nil,
                         {:domains_directory => test_domains_dir}.merge(options))
  end
end

require "#{File.dirname(__FILE__)}/glassfish/tasks/base_task_test.rb"
