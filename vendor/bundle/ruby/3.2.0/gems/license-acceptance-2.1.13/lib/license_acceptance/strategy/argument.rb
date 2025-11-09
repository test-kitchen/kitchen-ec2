require_relative "base"

module LicenseAcceptance
  module Strategy

    # Look for acceptance values in the ARGV
    class Argument < Base

      FLAG = "--chef-license".freeze

      attr_reader :argv

      def initialize(argv)
        @argv = argv
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
        argv.any? { |s| s == FLAG || s.start_with?("#{FLAG}=") }
      end

      def value
        match = argv.detect { |s| s.start_with?("#{FLAG}=") }
        return match.split("=").last if match

        argv.each_cons(2) do |arg, value|
          return value if arg == FLAG
        end

        nil
      end
    end
  end
end
