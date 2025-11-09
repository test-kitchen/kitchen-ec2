# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # The Librarian-Chef depsolving project is no longer maintained and a Cheffile should not be used for cookbook depsolving. Consider using Policyfiles instead. If the Policyfiles model is not compatible with your workflow you may find Berkshelf offers a more similar, and still supported, experience to Librarian-Chef.
        #
        class Cheffile < Base
          include RangeHelp

          MSG = 'The Librarian-Chef depsolving project is no longer maintained and a Cheffile should not be used for cookbook depsolving. Consider using Policyfiles instead.'

          def on_new_investigation
            # Using range similar to RuboCop::Cop::Naming::Filename (file_name.rb)
            range = source_range(processed_source.buffer, 1, 0)

            add_offense(range, severity: :warning)
          end
        end
      end
    end
  end
end
