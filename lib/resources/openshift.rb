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
    filter.register_column(:ids, field: 'name')
        .register_column(:status, field: 'status')
        .register_column(:status, field: 'hostIP')
        .register_column(:status, field: 'podIP')
        .register_column(:status, field: 'namespace')
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
      return @command if defined?(@command)
      data = inspec.backend.command_via_oc(cmd)
      @command = data
    end

    def to_s
      'Openshift Host'
    end

    def object(id)
      return @object if defined?(@object)
      command = "get pod/#{id} -o json"
      cmd = inspec.backend.command_via_oc(command).stdout
      json_output = JSON.parse(cmd)
      @object = json_output
    end
    private

    def parse_pods
      return @inspect if defined?(@inspect)
      row = nil
      command = "get pods -o json"
      cmd = inspec.backend.command_via_oc(command).stdout
      json_output = JSON.parse(cmd)
      output = []
      json_output['items'].each do |pod|
        name = pod['metadata']['name']
        namespace = pod['metadata']['namespace']
        pod_ip = pod['status']['podIP']
        host_ip = pod['status']['hostIP']
        status = pod['status']['phase']
        row = {"name" => name, "namespace" => namespace, "podIP" => pod_ip, "hostIP" => host_ip, "status" => status}
        output.push(row)
      end

      @inspect = output
    end

  end
end
