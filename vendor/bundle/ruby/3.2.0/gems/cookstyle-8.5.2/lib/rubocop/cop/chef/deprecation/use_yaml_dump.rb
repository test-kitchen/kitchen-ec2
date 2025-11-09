# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
# Author:: Tim Smith (<tsmith84@gmail.com>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module RuboCop
  module Cop
    module Chef
      module Deprecations
        # Chef Infra Client 16.5 introduced performance enhancements to Ruby library loading. Due to the underlying implementation of Ruby's `.to_yaml` method, it does not automatically load the `yaml` library and `YAML.dump()` should be used instead to properly load the `yaml` library.
        #
        # @example
        #
        #   ### incorrect
        #   {"foo" => "bar"}.to_yaml
        #
        #   ### correct
        #   YAML.dump({"foo" => "bar"})
        #
        class UseYamlDump < Base
          extend AutoCorrector

          MSG = "Chef Infra Client 16.5 introduced performance enhancements to Ruby library loading. Due to the underlying implementation of Ruby's `.to_yaml` method, it does not automatically load the `yaml` library and `YAML.dump()` should be used instead to properly load the `yaml` library."
          RESTRICT_ON_SEND = [:to_yaml].freeze

          def on_send(node)
            add_offense(node, severity: :warning) do |corrector|
              corrector.replace(node, "YAML.dump(#{node.receiver.source})")
            end
          end
        end
      end
    end
  end
end
