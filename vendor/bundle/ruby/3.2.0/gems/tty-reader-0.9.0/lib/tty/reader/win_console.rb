# frozen_string_literal: true

require_relative "keys"

module TTY
  class Reader
    class WinConsole
      ESC     = "\e"
      NUL_HEX = "\x00"
      EXT_HEX = "\xE0"

      # Key codes
      #
      # @return [Hash[Symbol]]
      #
      # @api public
      attr_reader :keys

      # Escape codes
      #
      # @return [Array[Integer]]
      #
      # @api public
      attr_reader :escape_codes

      def initialize(input)
        require_relative "win_api"
        @input = input
        @keys = Keys.ctrl_keys.merge(Keys.win_keys)
        @escape_codes = [[NUL_HEX.ord], [ESC.ord], EXT_HEX.bytes.to_a]
      end

      # Get a character from console blocking for input
      #
      # @param [Boolean] echo
      #   whether to echo input back or not, defaults to true
      # @param [Boolean] raw
      #   whether to use raw mode or not, defaults to false
      # @param [Boolean] nonblock
      #   whether to wait for input or not, defaults to false
      #
      # @return [String]
      #
      # @api private
      def get_char(echo: true, raw: false, nonblock: false)
        if raw && echo
          if nonblock
            get_char_echo_non_blocking
          else
            get_char_echo_blocking
          end
        elsif raw && !echo
          nonblock ? get_char_non_blocking : get_char_blocking
        elsif !raw && !echo
          nonblock ? get_char_non_blocking : get_char_blocking
        else
          @input.getc
        end
      end

      # Get the char for last key pressed, or if no keypress return nil
      #
      # @api private
      def get_char_non_blocking
        input_ready? ? get_char_blocking : nil
      end

      def get_char_echo_non_blocking
        input_ready? ? get_char_echo_blocking : nil
      end

      def get_char_blocking
        WinAPI.getch.chr
      end

      def get_char_echo_blocking
        WinAPI.getche.chr
      end

      # Check if IO has user input
      #
      # @return [Boolean]
      #
      # @api private
      def input_ready?
        !WinAPI.kbhit.zero?
      end
    end # Console
  end # Reader
end # TTY
