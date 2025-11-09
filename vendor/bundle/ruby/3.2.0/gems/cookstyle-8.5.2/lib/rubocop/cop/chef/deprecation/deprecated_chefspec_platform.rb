# frozen_string_literal: true
#
# Copyright:: 2020-2022, Chef Software Inc.
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
        # Use currently supported platforms in ChefSpec listed at https://github.com/chef/fauxhai/blob/main/PLATFORMS.md. Fauxhai / ChefSpec will perform fuzzy matching on platform version values so it's always best to be less specific ie. 10 instead of 10.3
        #
        # @example
        #
        #   let(:chef_run) { ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04') }
        #
        class DeprecatedChefSpecPlatform < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = "Use currently supported platforms in ChefSpec listed at https://github.com/chef/fauxhai/blob/main/PLATFORMS.md. Fauxhai / ChefSpec will perform fuzzy matching on platform version so it's always best to be less specific ie. 10 instead of 10.3"

          DEPRECATED_MAPPING = {
            'amazon' => {
              '2017.12' => '2',
              '> 2010' => true,
            },
            'aix' => {
              '~> 6' => true,
            },
            'smartos' => {
              '5.10' => true,
            },
            'ubuntu' => {
              '< 16.04' => true,
              '> 16.04, < 18.04' => true,
            },
            'fedora' => {
              '< 32' => '32',
            },
            'freebsd' => {
              '= 12.0' => '12',
              '< 12' => true,
            },
            'mac_os_x' => {
              '< 10.14' => '10.15',
              ' = 11.0' => '11',
            },
            'suse' => {
              '~> 12.0, < 12.4' => '12',
              '< 12' => true,
            },
            'opensuse' => {
              '< 14' => true,
              '~> 42.0' => true,
              '~> 15.0, < 15.2' => '15',
            },
            'debian' => {
              '< 9' => true,
              '> 9.0, < 9.12' => '9',
            },
            'centos' => {
              '< 6.0' => true,
              '~> 6.0, < 6.10' => '6',
              '~> 7.0, < 7.8 ' => '7',
            },
            'redhat' => {
              '< 6.0' => true,
              '~> 6.0, < 6.10' => '6',
              '~> 7.0, < 7.8' => '7',
            },
            'oracle' => {
              '< 6.0' => true,
              '~> 6.0, < 6.10' => '6',
              '~> 7.0, < 7.6 ' => '7',
            },
          }.freeze

          def_node_matcher :chefspec_definition?, <<-PATTERN
            (send (const (const nil? :ChefSpec) ... ) :new (hash <(pair (sym :platform) $(str ... )) (pair (sym :version) $(str ... )) ... >))
          PATTERN

          def legacy_chefspec_platform(platform, version)
            return false unless DEPRECATED_MAPPING.key?(platform)

            DEPRECATED_MAPPING[platform].each_pair do |match_string, replacement|
              return true if Gem::Dependency.new('', match_string.split(',')).match?('', version) &&
                             replacement != version # we want to catch '7.0' and suggest '7', but not alert on '7'
            end

            false
          end

          def replacement_string(platform, version)
            DEPRECATED_MAPPING[platform].each_pair do |match_string, replacement|
              return replacement if Gem::Dependency.new('', match_string.split(',')).match?('', version) &&
                                    replacement != version && # we want to catch '7.0' and suggest '7', but not alert on '7'
                                    replacement != true # true means it's busted, but requires human intervention to fix
            end

            nil # we don't have a replacement os return nil
          end

          def on_send(node)
            chefspec_definition?(node) do |plat, ver|
              next unless legacy_chefspec_platform(plat.value, ver.value)
              add_offense(node, severity: :warning) do |corrector|
                if replacement = replacement_string(plat.value, ver.value) # rubocop: disable Lint/AssignmentInCondition
                  corrector.replace(ver, "'#{replacement}'")
                end
              end
            end
          end
        end
      end
    end
  end
end
