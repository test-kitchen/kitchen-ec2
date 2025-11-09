# frozen_string_literal: true

#
# Copyright:: Copyright 2020, Chef Software Inc.
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
        # The OpenSSL cookbook provides a deprecated `secure_password` helper in the `Opscode::OpenSSL::Password` class, which should no longer be used. This helper would generate a random password that would be used when a data bag or attribute was no present. The practice of generating passwords to be stored on the node is bad security as it exposes the password to anyone that can view the nodes, and deleting a node deletes the password. Passwords should be retrieved from a secure source for use in cookbooks.
        #
        #   ### incorrect
        #   ::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
        #   basic_auth_password = secure_password
        #
        class OpenSSLPasswordHelpers < Base
          MSG = 'The `secure_password` helper from the openssl cookbooks `Opscode::OpenSSL::Password` class should not be used to generate passwords.'

          def_node_matcher :openssl_helper?, <<~PATTERN
            (const
              (const
                (const nil? :Opscode) :OpenSSL) :Password)
          PATTERN

          def on_const(node)
            openssl_helper?(node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
