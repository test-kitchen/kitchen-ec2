# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software, Inc.
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
      module Correctness
        # Use Ruby's built-in `File.exist?('C:\somefile')` method instead of executing PowerShell's `Test-Path` cmdlet, which takes longer to load.
        #
        # @example
        #
        #  ### incorrect
        #  powershell_out('Test-Path "C:\\Program Files\\LAPS\\CSE\\AdmPwd.dll"').stdout.strip == 'True'
        #
        #  ### correct
        #  ::File.exist?('C:\Program Files\LAPS\CSE\AdmPwd.dll')
        #
        class PowershellFileExists < Base
          RESTRICT_ON_SEND = [:powershell_out, :powershell_out!].freeze
          MSG = "Use Ruby's built-in `File.exist?('C:\\somefile')` method instead of executing PowerShell's `Test-Path` cmdlet, which takes longer to load."

          def_node_matcher :powershell_out_exists?, <<-PATTERN
            (send nil? {:powershell_out :powershell_out!} (str $_))
          PATTERN

          def on_send(node)
            powershell_out_exists?(node) do |exists_string|
              return unless exists_string.match?(/^Test-Path/)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
