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
      module Sharing
        # Use secure Github and Gitlab URLs for source_url and issues_url
        #
        # @example
        #
        #   ### incorrect
        #   source_url 'http://github.com/something/something'
        #   source_url 'http://www.github.com/something/something'
        #   source_url 'http://www.gitlab.com/something/something'
        #   source_url 'http://gitlab.com/something/something'
        #
        #   ### correct
        #   source_url 'http://github.com/something/something'
        #   source_url 'http://gitlab.com/something/something'
        #
        class InsecureCookbookURL < Base
          extend AutoCorrector

          MSG = 'Insecure http Github or Gitlab URLs for metadata source_url/issues_url fields'
          RESTRICT_ON_SEND = [:source_url, :issues_url].freeze

          def_node_matcher :insecure_cb_url?, <<-PATTERN
            (send nil? {:source_url :issues_url} (str #insecure_url?))
          PATTERN

          def insecure_url?(url)
            # https://rubular.com/r/dS6L6bQZvwWxWq
            url.match?(%r{http://(www.)*git(hub|lab)})
          end

          def on_send(node)
            insecure_cb_url?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, node.source.gsub(%r{http://(www.)*}, 'https://'))
              end
            end
          end
        end
      end
    end
  end
end
