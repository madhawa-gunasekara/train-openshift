# encoding: utf-8
#
# Author:: Madhawa Gunasekara(<madhawa30@gmail.com>)
#
# Copyright (C) 2019, Madhawa Gunasekara
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'train-openshift/platform'
require 'train/plugins'
require 'train/options'
require 'train/extras'

# This is a support library for our command meddling
require "open3"

module TrainPlugins
  module Openshift
    # Connection inherit from BaseConnection.
    class Connection < Train::Plugins::Transport::BaseConnection
      attr_reader :hostname
      # We've placed platform detection in a separate module; pull it in here.
      include TrainPlugins::Openshift::Platform

      DEFAULT_FILE = ::File.join('openshift-properties.yml')

      def initialize(options)
        super(options)
        if options[:credentials_file].nil? and options[:oc_path].nil? and options[:login_uri].nil? and options[:token].nil?
          options[:credentials_file] = DEFAULT_FILE
        end
        unless options[:credentials_file].nil?
          if File.file?(options[:credentials_file])
            logger.debug("[Openshift] Reading parameters from the file #{options[:credentials_file]}")
            properties = YAML.load(File.read(options[:credentials_file]))
            options[:oc_path] = properties['ocPath']
            options[:login_uri] = properties['serverUrl']
            options[:token] = properties['token']
            options[:project] = properties['project']
            logger.debug("[Openshift] Parameter uri: #{options[:credentials_file]}")
          end
        end
        @hostname = options.delete(:host)
        @serveruri = options.delete(:login_uri)
        @token = options.delete(:token)
        @ocpath = options.delete(:oc_path)
        @project = options.delete(:project)
        logger.debug("[Openshift] Parameter uri: #{@hostname}")
        logger.debug("[Openshift] Parameter token: #{@token}")
        logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
        validate
        establish_connection
      end

      def establish_connection
        logger.debug("opening connection to #{@serveruri}")
        oc = File.join(@ocpath, "oc")
        command = "#{oc} login #{@serveruri} --token=#{@token}"
        stdout, stderr, status = Open3.capture3(command)
        result = status.exitstatus
        logger.debug("[Openshift] Initialized oc client login #{result} with result output #{stdout}, with error #{stderr}")

        unless @project.nil?
          command = "#{oc} project #{@project}"
          stdout, stderr, status = Open3.capture3(command)
          result = status.exitstatus
          logger.debug("[Openshift] Switched to project to #{@project} with #{result} with result output #{stdout}, with error #{stderr}")
        end
      end

      def target
        @hostname
      end

      def command_via_oc(cmd)
        logger.debug("[Openshift] Start Executing command via oc")
        logger.debug("[Openshift] Parameter uri: #{@hostname}")
        logger.debug("[Openshift] Parameter token: #{@token}")
        logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
        logger.debug("[Openshift] Parameter command #{cmd}")
        result_output, error_output, status = Open3.capture3("#{@ocpath}/oc #{cmd}")
        result = status.exitstatus
        logger.debug("[Openshift] Parameter output #{result_output}")
        logger.debug("[Openshift] Parameter erroutput #{error_output}")
        logger.debug("[Openshift] Parameter result #{result}")
        logger.debug("[Openshift] Finish Executing command via oc")
        CommandResult.new(result_output, error_output, result)
      end

      def file_via_connection(path)
        logger.debug("[Openshift] Start Executing file via connection for #{@hostname}")
        logger.debug("[Openshift] Parameter uri: #{@hostname}")
        logger.debug("[Openshift] Parameter token: #{@token}")
        logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
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

      def validate
        if @ocpath.nil?
          fail Train::PluginLoadError, 'Openshift oc client path needs to be specified'
        end
        if @hostname.nil?
          fail Train::PluginLoadError, 'Openshift host/pod needs to be specified'
        end
        if @token.nil?
          fail Train::PluginLoadError, 'Openshift login token needs to be specified'
        end
        if @serveruri.nil?
          fail Train::PluginLoadError, 'Openshift login url needs to be specified'
        end
      end

      def run_command_via_connection(cmd)
        begin
          logger.debug("[Openshift] Start Executing run command via connection for #{@hostname}")
          logger.debug("[Openshift] Parameter uri: #{@hostname}")
          logger.debug("[Openshift] Parameter token: #{@token}")
          logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
          result = -1
          error_output = nil
          result_output = nil
          logger.debug("[Openshift] Parameter command #{cmd}")
          run_command = lambda do |command|
            Open3.popen3("#{@ocpath}/oc rsh #{@hostname}") do |stdin, stdout, stderr, wait_thr|
              stdin.puts command.to_s
              stdin.close_write
              result_output = stdout.read
              error_output = stderr.read
              result = wait_thr.value.exitstatus
            end
          end
          run_command [cmd]
          logger.debug("[Openshift] Parameter output #{result_output}")
          logger.debug("[Openshift] Parameter erroutput #{error_output}")
          logger.debug("[Openshift] Parameter result #{result}")
          logger.debug("[Openshift] Finish Executing run command via connection for #{@hostname}")
          CommandResult.new(result_output, error_output, result)
        rescue Exception => e
          fail Train::ClientError, e.message, e.backtrace
        end
      end
    end
  end
end
