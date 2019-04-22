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
        logger.info("parameter uri #{uri}")
        logger.info("parameter token #{token}")
        logger.info("parameter ocpath #{ocpath}")

        @session                = nil
        @transport_options      = @options.delete(:transport_options)
        @cmd_wrapper            = nil
        @cmd_wrapper            = CommandWrapper.load(self, @transport_options)
      end

      def close
        return if @session.nil?
        logger.debug("[SSH] closing connection to #{self}")
        session.close
      ensure
        @session = nil
      end

      # TODO: determine exactly what this is used for
      def uri
        "openshift://#{@options[:uri]}"
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
        logger.info("[SSH] opening connection to #{uri}")
        #implement oc login here
      end




      def file_via_connection(path)
          Train::File::Remote::Openshift.new(true, path)
      end

      def run_command_via_connection(cmd, &data_handler)
        cmd.dup.force_encoding('binary') if cmd.respond_to?(:force_encoding)
        logger.debug("[SSH] #{self} (#{cmd})")

        reset_session if session.closed?
        exit_status, stdout, stderr = execute_on_channel(cmd, &data_handler)

        # Since `@session.loop` succeeded, reset the IOS command retry counter
        @ios_cmd_retries = 0

        CommandResult.new(stdout, stderr, exit_status)
      rescue IOError
        # Cisco IOS occasionally closes the stream prematurely while we are
        # running commands to detect if we need to switch to the Cisco IOS
        # transport. This retries the command if this is the case.
        # See:
        #  https://github.com/inspec/train/pull/271
        logger.debug('[SSH] Possible Cisco IOS race condition, retrying command')

        # Only attempt retry up to 5 times to avoid infinite loop
        @ios_cmd_retries += 1
        raise if @ios_cmd_retries >= 5

        retry
      end

      # Returns a connection session, or establishes one when invoked the
      # first time.
      #
      # @param retry_options [Hash] retry options for the initial connection
      # @return [Net::SSH::Connection::Session] the SSH connection session
      # @api private
      def session(retry_options = {})
        @session ||= establish_connection({
                                              retries: @connection_retries.to_i,
                                              delay:   @connection_retry_sleep.to_i,
                                          }.merge(retry_options))
      end

      def reset_session
        @session = nil
      end

      # Given a channel and a command string, it will execute the command on the channel
      # and accumulate results in  @stdout/@stderr.
      #
      # @param channel [Net::SSH::Connection::Channel] an open ssh channel
      # @param cmd [String] the command to execute
      # @return [Integer] exit status or nil if exit-status/exit-signal requests
      #         not received.
      #
      # @api private
      def execute_on_channel(cmd, &data_handler)
        stdout = stderr = ''
        exit_status = nil
        session.open_channel do |channel|
          # wrap commands if that is configured
          cmd = @cmd_wrapper.run(cmd) unless @cmd_wrapper.nil?

          if @transport_options[:pty]
              channel.request_pty do |_ch, success|
              fail Train::Transports::SSHPTYFailed, 'Requesting PTY failed' unless success
            end
          end
          channel.exec(cmd) do |_, success|
            abort 'Couldn\'t execute command on SSH.' unless success
            channel.on_data do |_, data|
              yield(data) unless data_handler.nil?
              stdout += data
            end

            channel.on_extended_data do |_, _type, data|
              yield(data) unless data_handler.nil?
              stderr += data
            end

            channel.on_request('exit-status') do |_, data|
              exit_status = data.read_long
            end

            channel.on_request('exit-signal') do |_, data|
              exit_status = data.read_long
            end
          end
        end
        session.loop
        [exit_status, stdout, stderr]
      end
    end
  end
end
