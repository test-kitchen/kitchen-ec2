# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
        # Scope file exist to access the correct `File` class by using `::File.exist?` not `File.exist?`.
        #
        # @example
        #
        #   ### incorrect
        #   not_if { File.exist?('/etc/foo/bar') }
        #
        #   ### correct
        #   not_if { ::File.exist?('/etc/foo/bar') }
        #
        class ScopedFileExist < Base
          extend AutoCorrector

          MSG = 'Scope file exist to access the correct File class by using ::File.exist? not File.exist?.'

          def_node_matcher :unscoped_file_exist?, <<-PATTERN
          (block (send nil? {:not_if :only_if}) (args) (send $(const nil? :File) {:exist? :exists?} (...)))
          PATTERN

          def on_block(node)
            unscoped_file_exist?(node) do |m|
              add_offense(m, severity: :refactor) do |corrector|
                corrector.replace(m, '::File')
              end
            end
          end
        end
      end
    end
  end
end
