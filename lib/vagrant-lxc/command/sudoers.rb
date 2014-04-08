require 'tempfile'

module Vagrant
  module LXC
    module Command
      class Sudoers < Vagrant.plugin("2", :command)

        def initialize(argv, env)
          super
          @env = env
        end

        def execute
          options = { user: ENV['USER'] }

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant lxc sudoers"
            opts.separator ""
            opts.on('-u', '--user', "The user for which to create the policy (defaults to '#{options[:user]}')") do |u|
              options[:user] = u
            end
          end

          argv = parse_options(opts)
          return unless argv

          wrapper = create_wrapper!
          sudoers = create_sudoers!(options[:user], wrapper_path)

          su_copy([
            {source: wrapper, target: wrapper_path, mode: "0555"},
            {source: sudoers, target: sudoers_path, mode: "0440"}
          ])
        end

        def wrapper_path
          "/usr/local/bin/vagrant-lxc-wrapper-#{Vagrant::LXC::VERSION}"
        end
        
        def sudoers_path
          "/etc/sudoers.d/vagrant-lxc-#{Vagrant::LXC::VERSION.gsub( /\./, '-')}"
        end

        private
        # REFACTOR: Make use ERB rendering after https://github.com/mitchellh/vagrant/issues/3231
        #           lands into core
        def create_wrapper!
          wrapper = Tempfile.new('lxc-wrapper').tap do |file|
            file.puts "#!/usr/bin/env ruby"
            file.puts "# Automatically created by vagrant-lxc"
            file.puts <<-EOF
            class Whitelist
              class << self
                def add(command, *args)
                  list[command] << args
                end

                def list
                  @list ||= Hash.new do |key, hsh|
                    key[hsh] = []
                  end
                end

                def allowed(command)
                  list[command] || []
                end

                def run!(argv)
                  command, args = `which \#{argv.shift}`.chomp, argv || []
                  check!(command, args)
                  puts `\#{command} \#{args.join(" ")}`
                  exit $?.to_i
                end

                private
                def check!(command, args)
                  allowed(command).each do |checks|
                    args.each_with_index do |provided, i|
                      check = checks[i]
                      continue if match?(check, provided)
                      return if provided == args.last
                    end if args.length == checks.length
                  end
                  raise_invalid(command, args)
                end

                def match?(check, arg)
                  check == '**' || check.respond_to?(:match) && check.match(arg) || arg == check
                end

                def raise_invalid(command, args)
                  raise "Invalid arguments for command \#{command}, " <<
                    "provided args: \#{args.inspect}"
                end
              end
            end

            base_path = %r{\A/var/lib/lxc/.*}
            templates_path = %r{\A/use/(share|lib|lib64|local/lib)/lxc/templates/.*}
            boxes_path = %r{\A#{@env.boxes_path}/.*}

            ##
            # Commands from driver.rb
            # - Container config file
            Whitelist.add '/bin/cat', base_path
            # - Shared folders
            Whitelist.add '/bin/mkdir', '-p-', base_path
            # - Container config customizations and pruning
            Whitelist.add '/bin/su', 'root', '-c', 'sed', /.*/, '-ibak', base_path
            Whitelist.add '/bin/su', 'root', '-c', 'echo', /.*/, '>>', base_path
            # - Template import
            Whitelist.add '/bin/cp', boxes_path, templates_path
            Whitelist.add '/bin/chmod', '+x', templates_path
            # - Template removal
            Whitelist.add '/bin/rm', templates_path

            ##
            # Commands from driver/cli.rb
            Whitelist.add '/usr/bin/lxc-version'
            Whitelist.add '/usr/bin/lxc-info', '--name', /.*/
            Whitelist.add '/usr/bin/lxc-create' '--template', /.*/, '--name', /.*/, '**'
            Whitelist.add '/usr/bin/lxc-destroy',  '--name', /.*/
            Whitelist.add '/usr/bin/lxc-start', '--name', /.*/, '**'
            Whitelist.add '/usr/bin/lxc-stop', '--name', /.*/
            Whitelist.add '/usr/bin/lxc-shutdown' '--name', /.*/
            Whitelist.add '/usr/bin/lxc-attach' '--name', /.*/, '**'
            Whitelist.add '/usr/bin/lxc-attach' '-h'

            # Watch out for stones
            Whitelist.run!(ARGV)
            EOF
          end
          wrapper.close
          wrapper.path
        end

        # REFACTOR: Make use ERB rendering after https://github.com/mitchellh/vagrant/issues/3231
        #           lands into core
        def create_sudoers!(user, command)
          sudoers = Tempfile.new('vagrant-lxc-sudoers').tap do |file|
            file.puts "# Automatically created by vagrant-lxc"
            file.puts "Cmnd_Alias LXC = #{command}"
            file.puts "#{user} ALL=(root) NOPASSWD: LXC"
          end
          sudoers.close
          sudoers.path
        end

        def su_copy(files)
          commands = files.map { |file|
            [
              "rm -f #{file[:target]}",
              "cp #{file[:source]} #{file[:target]}",
              "chown root:root #{file[:target]}",
              "chmod #{file[:mode]} #{file[:target]}"
            ]
          }.flatten
          system "echo \"#{commands.join("; ")}\" | sudo sh"
        end
      end
    end
  end
end
