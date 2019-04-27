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
source 'https://rubygems.org'

# This is Gemfile, which is used by bundler
# to ensure a coherent set of gems is installed.
# This file lists dependencies needed when outside
# of a gem (the gemspec lists deps for gem deployment)

# Bundler should refer to the gemspec for any dependencies.
gemspec

# Remaining group is only used for development.
group :development do
  gem 'pry'
  gem 'bundler'
  gem 'byebug'
  gem 'inspec', '>= 2.2.112' # We need InSpec for the test harness while developing.
  gem 'minitest'
  gem 'mocha'
  gem 'm'
  gem 'rake'
  gem 'rubocop', '= 0.49.1' # Need to keep in sync with main InSpec project, so config files will work
end
