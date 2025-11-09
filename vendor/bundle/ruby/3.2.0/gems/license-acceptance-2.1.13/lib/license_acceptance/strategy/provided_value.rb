require_relative "base"

module LicenseAcceptance
  module Strategy

    # Used for library consumers to parse their own form of acceptance (knife config, omnibus config, etc.) and pass it in
    class ProvidedValue < Base
      attr_reader :value

      def initialize(value)
        @value = value
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
        !!value
      end
    end
  end
end
