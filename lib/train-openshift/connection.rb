# Connection definition file for an example Train plugin.

# Most of the work of a Train plugin happens in this file.
# Connections derive from Train::Plugins::Transport::BaseConnection,
# and provide a variety of services.  Later generations of the plugin
# API will likely separate out these responsibilities, but for now,
# some of the responsibilities include:
# * authentication to the target
# * platform / release /family detection
# * caching
# * API execution
# * marshalling to / from JSON
# You don't have to worry about most of this.

# Push platform detection out to a mixin, as it tends
# to develop at a different cadence than the rest
require 'train-openshift/platform'
require 'train/plugins'

# This is a support library for our command meddling
require "open3"
require "pp"
require 'ostruct'

module TrainPlugins
  module Openshift
    # You must inherit from BaseConnection.
    class Connection < Train::Plugins::Transport::BaseConnection
      # We've placed platform detection in a separate module; pull it in here.
      include TrainPlugins::Openshift::Platform

      def initialize(options)
        # 'options' here is a hash, Symbol-keyed,
        # of what Train.target_config decided to do with the URI that it was
        # passed by `inspec -t` (or however the application gathered target information)
        # Some plugins might use this moment to capture credentials from the URI,
        # and the configure an underlying SDK accordingly.
        # You might also take a moment to manipulate the options.
        # Have a look at the Local, SSH, and AWS transports for ideas about what
        # you can do with the options.

        # Override for any cli options
        #
        #@cmd_wrapper = CommandWrapper.load(self, @transport_options)

        # Now let the BaseConnection have a chance to configure itself.
        super(options)
        logger.info("parameter uri #{pod}")
        logger.info("parameter token #{token}")
        logger.info("parameter ocpath #{ocpath}")
      end


      # TODO: determine exactly what this is used for
      def pod
        "openshift://#{@options[:pod]}"
      end

      def serveruri
        "--serveruri://#{@options[:serveruri]}"
      end

      def token
        "--token=#{@options[:token]}"
      end

      def ocpath
        "--path=#{@options[:ocpath]}"
      end

      # Establish an SSH session on the remote host.
      #
      # @param opts [Hash] retry options
      # @option opts [Integer] :retries the number of times to retry before
      #   failing
      # @option opts [Float] :delay the number of seconds to wait until
      #   attempting a retry
      # @option opts [String] :message an optional message to be logged on
      #   debug (overriding the default) when a rescuable exception is raised
      # @return [Net::SSH::Connection::Session] the SSH connection session
      # @api private
      def establish_connection(opts)
        logger.info("opening connection to #{serveruri}")
        cmd = "." + ocpath + "/oc login " + serveruri + " --token=" + token
        stdout, stderr, status = Open3.capture3(cmd)
        result = status.exitstatus
        logger.info("initialized oc client login #{result}")
      end


      def file_via_connection(path)
        if os.aix?
          Train::File::Remote::Aix.new(self, path)
        elsif os.solaris?
          Train::File::Remote::Unix.new(self, path)
        elsif os[:name] == 'qnx'
          Train::File::Remote::Qnx.new(self, path)
        else
          Train::File::Remote::Linux.new(self, path)
        end
      end

      def run_command_via_connection(cmd)
        command_list = [
            "." + ocpath + "/oc rsh " + pod,
            cmd
        ]

        result = nil
        stdout, stderr, status = nil
        command_list.each do |command|
          stdout, stderr, status = Open3.capture3(command)
          result = status.exitstatus
          break if result != 0
        end
        # Wrap the results in a structure that Train expects...
        OpenStruct.new(
            # And meddle with the stdout along the way.
            stdout: stdout,
            stderr: stderr,
            exit_status: result,
        )
      end
    end
  end
end
