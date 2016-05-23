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

module Redfish
  class DomainDefinition < BaseElement
    def initialize(name, options = {}, &block)
      @name = name
      @data = Redfish::Mash.new
      @secure = true
      @port = nil
      @admin_username = nil
      @admin_password = nil
      @glassfish_home = nil
      @domains_directory = nil
      super(options, &block)
    end

    attr_reader :name
    attr_reader :data

    def secure?
      !!@secure
    end

    attr_writer :secure

    def port
      @port || 4848
    end

    attr_writer :port

    def admin_username
      @admin_username || 'admin'
    end

    attr_writer :admin_username

    def admin_password
      @admin_password ||= 10.times.map { [*('0'..'9'), *('A'..'Z'), *('a'..'z')].sample }.join
    end

    attr_writer :admin_password

    def glassfish_home
      @glassfish_home || Redfish::Config.default_glassfish_home
    end

    attr_writer :glassfish_home

    def domains_directory
      @domains_directory || Redfish::Config.default_domains_directory
    end

    attr_writer :domains_directory

    def to_task_context(executor = Redfish::Executor.new)
      Redfish::Context.new(executor,
                           self.glassfish_home,
                           self.name,
                           self.port,
                           self.secure?,
                           self.admin_username,
                           self.admin_password,
                           {:domains_directory => self.domains_directory})
    end
  end
end
