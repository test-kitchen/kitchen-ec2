# frozen_string_literal: true
module RuboCop
  # RuboCop Chef project namespace
  module Chef
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join('config', 'cookstyle.yml').freeze
    CONFIG         = YAML.load(CONFIG_DEFAULT.read).freeze

    private_constant(*constants(false))
  end
end
