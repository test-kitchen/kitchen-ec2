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
      module Modernize
        # The apt_repository resource allows setting up PPAs without using the full URL to ppa.launchpad.net, which should be used to simplify the resource code in your cookbooks.
        #
        # @example
        #
        #  ### incorrect
        #    apt_repository 'atom-ppa' do
        #      uri 'http://ppa.launchpad.net/webupd8team/atom/ubuntu'
        #      components ['main']
        #      keyserver 'keyserver.ubuntu.com'
        #      key 'C2518248EEA14886'
        #    end
        #
        #  ### correct
        #    apt_repository 'atom-ppa' do
        #      uri 'ppa:webupd8team/atom'
        #      components ['main']
        #      keyserver 'keyserver.ubuntu.com'
        #      key 'C2518248EEA14886'
        #    end
        #
        class SimplifyAptPpaSetup < Base
          extend AutoCorrector
          include RangeHelp
          include RuboCop::Chef::CookbookHelpers

          MSG = 'The apt_repository resource allows setting up PPAs without using the full URL to ppa.launchpad.net.'

          def on_block(node)
            match_property_in_resource?(:apt_repository, 'uri', node) do |uri|
              if %r{http(s)*://ppa.launchpad.net/(.*)/ubuntu$}.match?(uri.arguments&.first&.str_content)
                add_offense(uri, severity: :refactor) do |corrector|
                  next unless (replacement_val = %r{http(s)*://ppa.launchpad.net/(.*)/ubuntu}.match(node.source)[2])
                  corrector.replace(uri, "uri 'ppa:#{replacement_val}'")
                end
              end
            end
          end
        end
      end
    end
  end
end
