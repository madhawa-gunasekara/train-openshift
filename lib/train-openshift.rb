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
#
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'train-openshift/version'
# A train plugin has three components: Transport, Connection, and Platform.
# Transport acts as the glue.
require 'train-openshift/transport'
require 'train-openshift/platform'
require 'train-openshift/connection'