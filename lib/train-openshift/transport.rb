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
require 'train/plugins'
require 'train/options'


require 'train-openshift/connection'

module TrainPlugins
  module Openshift
    class Transport < Train.plugin(1)
      name 'openshift'

      option :host, required: true
      option :serveruri, default: ENV['SERVER']
      option :token, default: ENV['TOKEN']
      option :ocpath, default: ENV['OC_PATH']
      option :credentials_file, default: ENV['OPENSHIFT_CRED_FILE']


      # The only thing you MUST do in a transport is a define a
      # connection() method that returns a instance that is a
      # subclass of BaseConnection.
      def connection(_instance_opts = nil)
        @connection ||= TrainPlugins::Openshift::Connection.new(@options)
      end
    end
  end
end
