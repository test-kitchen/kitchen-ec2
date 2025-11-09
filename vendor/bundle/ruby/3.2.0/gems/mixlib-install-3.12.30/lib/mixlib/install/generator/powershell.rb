#
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "base"

module Mixlib
  class Install
    class Generator
      class PowerShell < Base
        def self.install_ps1(context)
          install_project_module = []
          install_project_module << get_script("helpers.ps1", context)
          install_project_module << get_script("get_project_metadata.ps1", context)
          install_project_module << get_script("install_project.ps1")

          install_command = []
          install_command << ps1_modularize(install_project_module.join("\n"), "Omnitruck")
          install_command.join("\n\n")
        end

        def self.detect_platform_ps1
          detect_platform_command = []
          detect_platform_command << get_script("helpers.ps1")
          detect_platform_command << get_script("platform_detection.ps1")
          detect_platform_command.join("\n\n")
        end

        def self.script_base_path
          File.join(File.dirname(__FILE__), "powershell/scripts")
        end

        def install_command
          install_project_module = []
          install_project_module << get_script("helpers.ps1", user_agent_headers: options.user_agent_headers)
          install_project_module << get_script("get_project_metadata.ps1")
          install_project_module << get_script("install_project.ps1")
          install_command = []
          install_command << ps1_modularize(install_project_module.join("\n"), "Omnitruck")
          install_command << render_command
          install_command.join("\n\n")
        end

        def self.ps1_modularize(module_body, module_name)
          ps1_module = []
          ps1_module << "new-module -name #{module_name} -scriptblock {"
          ps1_module << module_body
          ps1_module << "}"
          ps1_module.join("\n")
        end

        def ps1_modularize(module_body, module_name)
          self.class.ps1_modularize(module_body, module_name)
        end

        def render_command
          cmd = "install -project #{options.product_name}"
          cmd << " -version #{options.product_version}"
          cmd << " -channel #{options.channel}"
          cmd << " -architecture #{options.architecture}" if options.architecture
          cmd << install_command_params if options.install_command_options
          cmd << "\n"
        end

        def install_command_params
          options.install_command_options.map { |key, value| " -#{key} '#{value}'" }.join
        end
      end
    end
  end
end
