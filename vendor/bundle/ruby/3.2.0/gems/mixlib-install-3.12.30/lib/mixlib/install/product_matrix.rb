require_relative "product"

#
# If you are making a change to PRODUCT_MATRIX, please make sure
# you run `bundle exec rake matrix` at the home of this repository
# to update PRODUCT_MATRIX.md.
#
PRODUCT_MATRIX = Mixlib::Install::ProductMatrix.new do
  # Products in alphabetical order

  product "analytics" do
    product_name "Analytics Platform"
    package_name "opscode-analytics"
    ctl_command "opscode-analytics-ctl"
    config_file "/etc/opscode-analytics/opscode-analytics.rb"
    downloads_product_page_url :not_available
  end

  product "angry-omnibus-toolchain" do
    product_name "Angry Omnibus Toolchain"
    package_name "angry-omnibus-toolchain"
    github_repo "chef/omnibus-toolchain"
    downloads_product_page_url :not_available
  end

  product "angrychef" do
    product_name "Angry Chef Client"
    package_name "angrychef"
    github_repo "chef/chef"
    downloads_product_page_url :not_available
  end

  product "automate" do
    product_name "Chef Automate"
    # Delivery backward compatibility
    package_name do |v|
      v < version_for("0.7.0") ? "delivery" : "automate"
    end
    ctl_command do |v|
      v < version_for("0.7.0") ? "delivery-ctl" : "automate-ctl"
    end
    config_file "/etc/delivery/delivery.rb"
  end

  product "chef" do
    product_name "Chef Infra Client"
    package_name "chef"
  end

  product "chef-foundation" do
    product_name "Chef Foundation"
    package_name "chef-foundation"
  end

  product "chef-universal" do
    product_name "Chef Infra Client MacOS Universal"
    package_name "universal-package"
  end

  product "chef-backend" do
    product_name "Chef Backend"
    package_name "chef-backend"
    ctl_command "chef-backend-ctl"
    config_file "/etc/chef-backend/chef-backend.rb"
  end

  product "chef-server" do
    product_name "Chef Infra Server"
    package_name do |v|
      if (v < version_for("12.0.0")) && (v > version_for("11.0.0"))
        "chef-server"
      else
        "chef-server-core"
      end
    end
    omnibus_project "chef-server"
    ctl_command "chef-server-ctl"
    config_file do |v|
      if (v < version_for("12.0.0")) && (v > version_for("11.0.0"))
        "/etc/chef-server/chef-server.rb"
      else
        "/etc/opscode/chef-server.rb"
      end
    end
    install_path do |v|
      if (v < version_for("12.0.0")) && (v > version_for("11.0.0"))
        "/opt/chef-server"
      else
        "/opt/opscode"
      end
    end
  end

  product "chef-server-ha-provisioning" do
    product_name "Chef Infra Server HA Provisioning for AWS"
    package_name "chef-server-ha-provisioning"
    downloads_product_page_url :not_available
  end

  product "chef-workstation" do
    product_name "Chef Workstation"
    package_name "chef-workstation"
    github_repo "chef/chef-workstation"
  end

  product "chefdk" do
    product_name "Chef Development Kit"
    package_name "chefdk"
    github_repo "chef/chef-dk"
  end

  product "compliance" do
    product_name "Chef Compliance"
    package_name "chef-compliance"
    ctl_command "chef-compliance-ctl"
    config_file "/etc/chef-compliance/chef-compliance.rb"
  end

  product "delivery" do
    product_name "Delivery"
    # Chef Automate forward compatibility
    package_name do |v|
      v < version_for("0.7.0") ? "delivery" : "automate"
    end
    ctl_command do |v|
      v < version_for("0.7.0") ? "delivery-ctl" : "automate-ctl"
    end
    config_file "/etc/delivery/delivery.rb"
    github_repo "chef/automate"
    downloads_product_page_url "https://downloads.chef.io/automate"
  end

  product "ha" do
    product_name "Chef Infra Server High Availability addon"
    package_name "chef-ha"
    config_file "/etc/opscode/chef-server.rb"
    github_repo "chef/chef-ha"
    downloads_product_page_url :not_available
  end

  product "harmony" do
    product_name "Harmony - Omnibus Integration Internal Test Project"
    package_name "harmony"
    github_repo "chef/omnibus-harmony"
    downloads_product_page_url :not_available
  end

  product "inspec" do
    product_name "Chef InSpec"
    package_name "inspec"
  end

  product "mac-bootstrapper" do
    product_name "Habitat Mac Bootstrapper"
    package_name "mac-bootstrapper"
    downloads_product_page_url :not_available
  end

  product "manage" do
    product_name "Management Console"
    package_name do |v|
      v < version_for("2.0.0") ? "opscode-manage" : "chef-manage"
    end
    ctl_command do |v|
      v < version_for("2.0.0") ? "opscode-manage-ctl" : "chef-manage-ctl"
    end
    config_file do |v|
      if v < version_for("2.0.0")
        "/etc/opscode-manage/manage.rb"
      else
        "/etc/chef-manage/manage.rb"
      end
    end
    github_repo "chef/chef-manage"
  end

  product "marketplace" do
    product_name "Chef Cloud Marketplace addon"
    package_name "chef-marketplace"
    ctl_command "chef-marketplace-ctl"
    config_file "/etc/chef-marketplace/marketplace.rb"
    github_repo "chef-partners/omnibus-marketplace"
    downloads_product_page_url :not_available
  end

  product "omnibus-toolchain" do
    product_name "Omnibus Toolchain"
    package_name "omnibus-toolchain"
    downloads_product_page_url :not_available
  end

  product "omnibus-gcc" do
    product_name "Omnibus GCC Package"
    package_name "omnibus-gcc"
    downloads_product_page_url :not_available
  end

  product "private-chef" do
    product_name "Enterprise Chef (legacy)"
    package_name "private-chef"
    ctl_command "private-chef-ctl"
    config_file "/etc/opscode/private-chef.rb"
    install_path "/opt/opscode"
    github_repo "chef/opscode-chef"
  end

  product "push-jobs-client" do
    product_name "Chef Push Client"
    package_name do |v|
      v < version_for("1.3.0") ? "opscode-push-jobs-client" : "push-jobs-client"
    end
    github_repo "chef/opscode-pushy-client"
  end

  product "push-jobs-server" do
    product_name "Chef Push Server"
    package_name "opscode-push-jobs-server"
    ctl_command "opscode-push-jobs-server-ctl"
    config_file "/etc/opscode-push-jobs-server/opscode-push-jobs-server.rb"
    github_repo "chef/opscode-pushy-server"
  end

  product "reporting" do
    product_name "Chef Infra Server Reporting addon"
    package_name "opscode-reporting"
    ctl_command "opscode-reporting-ctl"
    config_file "/etc/opscode-reporting/opscode-reporting.rb"
    github_repo "chef/oc_reporting"
  end

  product "supermarket" do
    product_name "Supermarket"
    package_name "supermarket"
    ctl_command "supermarket-ctl"
    config_file "/etc/supermarket/supermarket.json"
  end

  product "sync" do
    product_name "Chef Infra Server Replication addon"
    package_name "chef-sync"
    ctl_command "chef-sync-ctl"
    config_file "/etc/chef-sync/chef-sync.rb"
    github_repo "chef/omnibus-sync"
    downloads_product_page_url :not_available
  end
end
