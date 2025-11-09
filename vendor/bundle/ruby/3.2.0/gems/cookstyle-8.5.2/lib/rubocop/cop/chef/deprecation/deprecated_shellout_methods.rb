# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # The large number of `shell_out` helper methods in Chef Infra Client has been reduced to just `shell_out` and `shell_out!` methods. The legacy methods were removed in Chef Infra Client and cookbooks using these legacy helpers will need to be updated.
        #
        # @example
        #
        #   ### incorrect
        #   shell_out_compact('foo')
        #   shell_out_compact!('foo')
        #   shell_out_with_timeout('foo')
        #   shell_out_with_timeout!('foo')
        #   shell_out_with_systems_locale('foo')
        #   shell_out_with_systems_locale!('foo')
        #   shell_out_compact_timeout('foo')
        #   shell_out_compact_timeout!('foo')
        #
        #   ### correct
        #   shell_out('foo')
        #   shell_out!('foo')
        #   shell_out!('foo', default_env: false) # replaces shell_out_with_systems_locale
        #
        class DeprecatedShelloutMethods < Base
          extend TargetChefVersion

          minimum_target_chef_version '14.3'

          MSG = 'Many legacy specialized shell_out methods were replaced in Chef Infra Client 14.3 and removed in Chef Infra Client 15. Use shell_out and any additional options if necessary.'
          RESTRICT_ON_SEND = %i( shell_out_compact
                                 shell_out_compact!
                                 shell_out_compact_timeout
                                 shell_out_compact_timeout!
                                 shell_out_with_timeout
                                 shell_out_with_timeout!
                                 shell_out_with_systems_locale
                                 shell_out_with_systems_locale!
        ).freeze

          def on_send(node)
            add_offense(node, severity: :warning)
          end
        end
      end
    end
  end
end
