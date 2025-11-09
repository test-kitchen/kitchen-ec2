# frozen_string_literal: true
#
# Copyright:: Chef Software, Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
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
      module Ruby
        # Rubygems is VERY slow to require gems even if they've already been loaded. To work around this
        # wrap your require statement with an `if defined?()` check.
        #
        class UnlessDefinedRequire < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = "Workaround rubygems slow requires by only running require if the class isn't already defined"

          REQUIRE_TO_CLASS = {
            'addressable/uri' => 'Addressable::URI',
            'appscript' => 'Appscript',
            'base64' => 'Base64',
            'benchmark' => 'Benchmark',
            'cgi' => 'CGI',
            'chef-utils' => 'ChefUtils::CANARY',
            'chef-utils/dist' => 'ChefUtils::Dist',
            'csv' => 'CSV',
            'digest' => 'Digest',
            'digest/md5' => 'Digest::MD5',
            'digest/sha1' => 'Digest::SHA1',
            'digest/sha2' => 'Digest::SHA2',
            'droplet_kit' => 'DropletKit',
            'erb' => 'Erb',
            'erubis' => 'Erubis',
            'etc' => 'Etc',
            'excon' => 'Excon',
            'faraday' => 'Faraday',
            'ffi_yajl' => 'FFI_Yajl',
            'ffi' => 'FFI',
            'fileutils' => 'FileUtils',
            'find' => 'Find.find',
            'forwardable' => 'Forwardable',
            'ipaddr' => 'IPAddr',
            'json' => 'JSON',
            'mime/types' => 'MIME::Types',
            'mixlib/archive' => 'Mixlib::Archive',
            'mixlib/cli' => 'Mixlib::CLI',
            'mixlib/config' => 'Mixlib::Config',
            'mixlib/shellout' => 'Mixlib::ShellOut',
            'multi_json' => 'MultiJson',
            'net/http' => 'Net::HTTP',
            'net/ssh' => 'Net::SSH',
            'netaddr' => 'NetAddr',
            'nokogiri' => 'Nokogiri',
            'ohai' => 'Ohai::System',
            'open-uri' => 'OpenURI',
            'openssl' => 'OpenSSL',
            'optparse' => 'OptionParser',
            'ostruct' => 'OpenStruct',
            'pathname' => 'Pathname',
            'pp' => 'PP',
            'rack' => 'Rack',
            'rbconfig' => 'RbConfig',
            'retryable' => 'Retryable',
            'rexml/document' => 'REXML::Document',
            'rubygems' => 'Gem',
            'rubygems/package' => 'Gem::Package',
            'securerandom' => 'SecureRandom',
            'set' => 'Set',
            'shellwords' => 'Shellwords',
            'singleton' => 'Singleton',
            'socket' => 'Socket',
            'sslshake' => 'SSLShake',
            'stringio' => 'StringIO',
            'tempfile' => 'Tempfile',
            'thor' => 'Thor',
            'time' => 'Time.zone_offset',
            'timeout' => 'Timeout',
            'tmpdir' => 'Dir.mktmpdir',
            'tomlrb' => 'Tomlrb',
            'uri' => 'URI',
            'webrick' => 'WEBrick',
            'win32/registry' => 'Win32::Registry',
            'win32ole' => 'WIN32OLE',
            'winrm' => 'WinRM::Connection',
            'yard' => 'YARD',
            'zip' => 'Zip',
            'zlib' => 'Zlib',
            'pastel' => 'Pastel',
          }.freeze

          def_node_matcher :require?, <<-PATTERN
            (send nil? :require (str $_) )
          PATTERN

          def on_send(node)
            require?(node) do |r|
              next if node.parent && node.parent.conditional? # catch both if and unless
              next unless REQUIRE_TO_CLASS[r]

              add_offense(node.loc.expression, message: MSG, severity: :refactor) do |corrector|
                corrector.replace(node.loc.expression, "#{node.source} unless defined?(#{REQUIRE_TO_CLASS[r]})")
              end
            end
          end
        end
      end
    end
  end
end
