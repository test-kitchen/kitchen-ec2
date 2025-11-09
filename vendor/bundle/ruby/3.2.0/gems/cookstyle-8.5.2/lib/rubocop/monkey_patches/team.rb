# frozen_string_literal: true

module RuboCop
  module Cop
    class Team
      def support_target_chef_version?(cop)
        return true unless cop.class.respond_to?(:support_target_chef_version?)

        cop.class.support_target_chef_version?(cop.target_chef_version)
      end

      ### START COOKSTYLE MODIFICATION
      def roundup_relevant_cops(processed_source)
        cops.select do |cop|
          next true if processed_source.comment_config.cop_opted_in?(cop)
          next false if cop.excluded_file?(processed_source.file_path)
          next false unless @registry.enabled?(cop, @config)

          support_target_ruby_version?(cop) && support_target_rails_version?(cop) && support_target_chef_version?(cop)
        end
      end
      ### END COOKSTYLE MODIFICATION
    end
  end
end
