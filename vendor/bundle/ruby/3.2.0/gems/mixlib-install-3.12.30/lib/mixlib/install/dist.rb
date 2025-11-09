module Mixlib
  class Install
    class Dist
      # This class is not fully implemented, depending it is not recommended!
      # Default project name
      PROJECT_NAME = "Chef".freeze
      # Binary repository base endpoint
      PRODUCT_ENDPOINT = "https://packages.chef.io".freeze
      # Omnitruck endpoint
      OMNITRUCK_ENDPOINT = "https://omnitruck.chef.io".freeze
      # Default product name
      DEFAULT_PRODUCT = "chef".freeze
      # Default download page URL
      DOWNLOADS_PAGE = "https://downloads.chef.io".freeze
      # Default github org
      GITHUB_ORG = "chef".freeze
      # Bug report URL
      BUG_URL = "https://github.com/chef/omnitruck/issues/new".freeze
      # Support ticket URL
      SUPPORT_URL = "https://www.chef.io/support/tickets".freeze
      # Resources URL
      RESOURCES_URL = "https://www.chef.io/support".freeze
      # MacOS volume name
      MACOS_VOLUME = "chef_software".freeze
      # Windows install directory name
      WINDOWS_INSTALL_DIR = "opscode".freeze
      # Linux install directory name
      LINUX_INSTALL_DIR = "/opt"
    end
  end
end
