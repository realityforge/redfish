module Redfish
  class Executor
    def exec(context, asadmin_command, args = [], options = {})
      raise 'args should be an array' unless args.is_a?(Array)

      cmd = build_command(context, asadmin_command, args, options)

      output = nil
      IO.popen(cmd,'r') do |pipe|
        output = pipe.read
      end

      raise "Asadmin command failed #{asadmin_command} with exist status #{last_exitstatus}" if 0 != last_exitstatus
      output
    end

    private

    def last_exitstatus
      $?.exitstatus
    end

    def build_command(context, asadmin_command, args, options)
      cmd = []

      if needs_user_change?(context)
        cmd << '/usr/bin/sudo'
        cmd << '-u' << context.system_user.to_s unless context.system_user.nil?
        cmd << '-g' << context.system_group.to_s unless context.system_group.nil?
      end

      cmd << asadmin_script(context)
      cmd += asadmin_command_prefix(context, options)
      cmd << asadmin_command
      cmd += args

      Redfish.debug("Executing #{cmd.join(' ')}")

      cmd
    end

    def needs_user_change?(context)
      (context.system_user.nil? ? false : Etc.getlogin.to_s != context.system_user.to_s) ||
        (context.system_group.nil? ? false : Etc.group.name.to_s != context.system_group.to_s)
    end

    def asadmin_command_prefix(context, options = {})
      terse = options[:terse].nil? ? context.terse? : options[:terse]
      echo = options[:echo].nil? ? context.echo? : options[:echo]
      remote_command = options[:remote_command].nil? || !!options[:remote_command]

      args = []
      args << "--terse=#{terse}"
      args << "--echo=#{echo}"
      args << '--user' << context.domain_username.to_s if context.domain_username
      args << "--passwordfile=#{context.domain_password_file}" if context.domain_password_file
      if remote_command
        args << '--secure' if context.domain_secure
        args << '--port' <<  context.domain_admin_port.to_s
      end
    end

    def asadmin_script(context)
      "#{context.install_dir}/glassfish/bin/asadmin"
    end
  end
end
