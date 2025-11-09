# frozen_string_literal: true

module RuboCop
  class Config
    # This is a copy of the #target_rails_version method from RuboCop
    def target_chef_version
      @target_chef_version ||=
        if for_all_cops['TargetChefVersion']
          for_all_cops['TargetChefVersion'].to_f
        else
          99 # just set a high number so we don't need to update this later
        end
    end
  end
end
