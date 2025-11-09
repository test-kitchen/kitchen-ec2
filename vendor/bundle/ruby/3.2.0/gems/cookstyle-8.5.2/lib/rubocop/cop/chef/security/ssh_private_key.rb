# frozen_string_literal: true
#
# Copyright:: 2021-2022, Chef Software, Inc.
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
      module Security
        # Do not include plain text SSH private keys in your cookbook code. This sensitive data should be fetched from secrets management systems so that secrets are not uploaded in plain text to the Chef Infra Server or committed to source control systems.
        #
        # @example
        #
        #   ### incorrect
        #   file '/Users/bob_bobberson/.ssh/id_rsa' do
        #     content '-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----'
        #     mode '600'
        #   end
        #
        class SshPrivateKey < Base
          MSG = 'Do not include plain text SSH private keys in your cookbook code. This sensitive data should be fetched from secrets management systems so that secrets are not uploaded in plain text to the Chef Infra Server or committed to source control systems.'

          def on_send(node)
            return unless node.arguments?
            node.arguments.each do |arg|
              next unless arg.str_type? || arg.dstr_type?

              if arg.value.start_with?('-----BEGIN RSA PRIVATE', '-----BEGIN EC PRIVATE')
                add_offense(node, severity: :warning)
              end
            end
          end
        end
      end
    end
  end
end
