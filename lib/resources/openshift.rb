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
require 'utils/filter'

module Inspec::Resources
  class OpenshiftPodFilter
    # use filterTable for pods
    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) {|x| !x.entries.empty?}
    filter.register_column(:ids, field: 'id')
        .register_column(:status, field: 'status')
        .register_custom_matcher(:running?) {|x|
          x.where {status.downcase.start_with?('running')}
        }
    filter.install_filter_methods_on_resource(self, :pods)

    attr_reader :pods

    def initialize(pods)
      @pods = pods
    end
  end

  class Openshift < Inspec.resource(1)
    name 'openshift'
    supports platform: 'openshift'

    desc "A resource to retrieve information about openshift"

    example <<~EXAMPLE
      describe docker.pods do
        its('ids') { should_not include 'u12:latest' }
      end

    EXAMPLE

    def pods
      OpenshiftPodFilter.new(parse_pods)
    end

    # returns information about docker objects
    def command(cmd)
      return @inspect if defined?(@inspect)
      data = inspec.command("OCR: #{cmd}")
      @inspect = data
    end

    def to_s
      'Openshift Host'
    end

    private

    def parse_pods
      return @inspect if defined?(@inspect)
      row = nil
      command = "OCR: get pods"
      cmd = inspec.command(command).stdout
      output = []
      cmd.each_line {|entry|
        if entry.count("0-9") > 0
          params = entry.split(" ")
          json = "{
              \"id\" : \"#{params[0]}\",
              \"status\" : \"#{params[2]}\"
          }"
          row = JSON.parse(json).map { |key, value|
            [key.downcase, value]
          }.to_h
          output.push(row)
        end
      }
      @inspect = output
    end

  end
end
