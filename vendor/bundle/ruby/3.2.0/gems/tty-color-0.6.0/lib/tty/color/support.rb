# frozen_string_literal: true

module TTY
  module Color
    class Support
      SOURCES = %w[from_term from_tput from_env from_curses].freeze
      ENV_VARS = %w[COLORTERM ANSICON].freeze

      TERM_REGEX = /
        color|  # explicitly claims color support in the name
        direct| # explicitly claims "direct color" (24 bit) support

        #{Mode::TERM_256}|
        #{Mode::TERM_64}|
        #{Mode::TERM_52}|
        #{Mode::TERM_16}|
        #{Mode::TERM_8}|

        ^ansi(\.sys.*)?$|
        ^cygwin|
        ^linux|
        ^putty|
        ^rxvt|
        ^screen|
        ^tmux|
        ^xterm/xi.freeze

      # Initialize a color support
      # @api public
      def initialize(env, verbose: false)
        @env = env
        @verbose = verbose
      end

      # Detect if terminal supports color
      #
      # @return [Boolean]
      #   true when terminal supports color, false otherwise
      #
      # @api public
      def support?
        return false unless TTY::Color.tty?
        return false if disabled?

        value = false
        SOURCES.each do |from_check|
          break if (value = public_send(from_check)) != NoValue
        end
        value == NoValue ? false : value
      end

      # Detect if color support has been disabled with NO_COLOR ENV var.
      #
      # @return [Boolean]
      #   true when terminal color support has been disabled, false otherwise
      #
      # @api public
      def disabled?
        no_color = @env["NO_COLOR"]
        !(no_color.nil? || no_color.empty?)
      end

      # Inspect environment $TERM variable for color support
      #
      # @api private
      def from_term
        case @env["TERM"]
        when "dumb" then false
        when TERM_REGEX then true
        else NoValue
        end
      end

      # Shell out to tput to check color support
      #
      # @api private
      def from_tput
        return NoValue unless TTY::Color.command?("tput colors")

        `tput colors 2>/dev/null`.to_i > 2
      rescue Errno::ENOENT
        NoValue
      end

      # Check if environment specifies color variables
      #
      # @api private
      def from_env
        ENV_VARS.any? { |key| @env.key?(key) } || NoValue
      end

      # Attempt to load curses to check color support
      #
      # @return [Boolean]
      #
      # @api private
      def from_curses(curses_class = nil)
        return NoValue if TTY::Color.windows?

        require "curses"

        if defined?(Curses)
          curses_class ||= Curses
          curses_class.init_screen
          has_color = curses_class.has_colors?
          curses_class.close_screen
          return has_color
        end
        NoValue
      rescue LoadError
        warn "no native curses support" if @verbose
        NoValue
      end
    end # Support
  end # Color
end # TTY
