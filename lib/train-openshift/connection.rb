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
require "pp"
require 'ostruct'

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
        options[:credentials_file] = DEFAULT_FILE if options[:credentials_file].nil?
        if File.file?(options[:credentials_file])
          logger.debug("[Openshift] Reading parameters from the file #{options[:credentials_file]}")
          properties = YAML.load(File.read(options[:credentials_file]))
          options[:ocpath] = properties['ocPath']
          options[:serveruri] = properties['serverUrl']
          options[:token] = properties['token']
        end
        @hostname = options.delete(:host)
        @serveruri = options.delete(:serveruri)
        @token = options.delete(:token)
        @ocpath = options.delete(:ocpath)
        logger.debug("[Openshift] Parameter uri: #{@hostname}")
        logger.debug("[Openshift] Parameter token: #{@token}")
        logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
      end

      def establish_connection
        logger.debug("opening connection to #{@serveruri}")
        command = "#{@ocpath}/oc login #{@serveruri} --token=#{@token}"
        stdout, stderr, status = Open3.capture3(command)
        result = status.exitstatus
        logger.debug("initialized oc client login #{result}")
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

      def run_command_via_connection(cmd)
        begin
          logger.debug("[Openshift] Start Executing run command via connection for #{@hostname}")
          logger.debug("[Openshift] Parameter uri: #{@hostname}")
          logger.debug("[Openshift] Parameter token: #{@token}")
          logger.debug("[Openshift] Parameter ocpath: #{@ocpath}")
          command = "#{@ocpath}/oc login #{@serveruri} --token=#{@token}"
          sout, serr, status = Open3.capture3(command)
          result = status.exitstatus
          result = 0
          erroutput = nil
          output = nil
          logger.debug("[Openshift] Parameter command #{cmd}")
          test = lambda do |command|
            Open3.popen3("#{@ocpath}/oc rsh #{@hostname}") do |stdin, stdout, stderr, wait_thr|
              stdin.puts command.to_s
              stdin.close_write
              output = stdout.read
              erroutput = stderr.read
              result = wait_thr.value.exitstatus
            end
          end
          test [cmd]
          logger.debug("[Openshift] Parameter output #{output}")
          logger.debug("[Openshift] Parameter erroutput #{erroutput}")
          logger.debug("[Openshift] Parameter result #{result}")
          logger.debug("[Openshift] Finish Executing run command via connection for #{@hostname}")
          CommandResult.new(output, erroutput, result)
        rescue Exception => e
          puts e.message
          puts e.backtrace
        end
      end
    end
  end
end
