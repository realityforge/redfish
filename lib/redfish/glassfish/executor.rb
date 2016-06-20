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
  class Executor
    def exec(context, asadmin_command, args = [], options = {})
      cmd = build_command(context, asadmin_command, args, options)

      Redfish.debug("Executing #{cmd.join(' ')}")

      output = nil
      IO.popen(cmd, 'r') do |pipe|
        output = pipe.read
      end

      if 0 != last_exitstatus
        Redfish.warn("Command: #{cmd.inspect}")
        Redfish.warn(output)
        message = "Asadmin command failed #{asadmin_command} with exist status #{last_exitstatus}"
        Redfish.warn(message)
        raise message
      end
      output
    end

    def build_command(context, asadmin_command, args = [], options = {})
      raise 'args should be an array' unless args.is_a?(Array)

      cmd = []

      # :sudo option defaults to true unless explicitly set to false
      if needs_user_change?(context) && (options[:sudo].nil? || options[:sudo])
        cmd << '/usr/bin/sudo'
        cmd << '-u' << context.system_user.to_s unless context.system_user.nil?
        cmd << '-g' << context.system_group.to_s unless context.system_group.nil?
      end

      # :authbind option defaults to true unless explicitly set to false
      unless context.authbind_executable.nil? || (options[:authbind] && !options[:authbind])
        cmd << context.authbind_executable
        cmd << '--deep'
      end

      cmd << asadmin_script(context)
      cmd += asadmin_command_prefix(context, options)
      cmd << asadmin_command
      cmd += args

      cmd
    end

    private

    def last_exitstatus
      $?.exitstatus
    end

    def needs_user_change?(context)
      (context.system_user.nil? ? false : Etc.getlogin.to_s != context.system_user.to_s) ||
        (context.system_group.nil? ? false : Etc.group.name.to_s != context.system_group.to_s)
    end

    def asadmin_command_prefix(context, options = {})
      terse = options[:terse].nil? ? context.terse? : options[:terse]
      echo = options[:echo].nil? ? context.echo? : options[:echo]
      remote_command = options[:remote_command].nil? || !!options[:remote_command]
      domain_password_file = options[:domain_password_file] || context.domain_password_file
      secure = options[:secure].nil? ? context.domain_secure : options[:secure]

      args = []
      args << "--terse=#{terse}"
      args << "--echo=#{echo}"
      args << '--user' << context.domain_username.to_s if context.domain_username
      args << "--passwordfile=#{domain_password_file}" if domain_password_file
      if remote_command
        args << '--secure' if secure
        args << '--port' << context.domain_admin_port.to_s
      end
    end

    def asadmin_script(context)
      "#{context.install_dir}/glassfish/bin/asadmin"
    end
  end
end
