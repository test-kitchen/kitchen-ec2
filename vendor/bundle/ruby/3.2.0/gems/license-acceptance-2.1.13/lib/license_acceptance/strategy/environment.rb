require_relative "base"

module LicenseAcceptance
  module Strategy

    # Look for acceptance values in the environment
    class Environment < Base

      ENV_KEY = "CHEF_LICENSE".freeze

      attr_reader :env

      def initialize(env)
        @env = env
      end

      def accepted?
        String(value).downcase == ACCEPT
      end

      def silent?
        String(value).downcase == ACCEPT_SILENT
      end

      def no_persist?
        String(value).downcase == ACCEPT_NO_PERSIST
      end

      def value?
        env.key?(ENV_KEY)
      end

      def value
        env[ENV_KEY]
      end

    end
  end
end
