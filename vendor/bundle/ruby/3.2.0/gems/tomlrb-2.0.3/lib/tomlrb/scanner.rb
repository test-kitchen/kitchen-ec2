require 'strscan'

module Tomlrb
  class Scanner
    COMMENT = /#[^\u0000-\u0008\u000A-\u001F\u007F]*/
    IDENTIFIER = /[A-Za-z0-9_-]+/
    SPACE = /[ \t]/
    NEWLINE = /(?:[ \t]*(?:\r?\n)[ \t]*)+/
    STRING_BASIC = /(["])(?:\\?[^\u0000-\u0008\u000A-\u001F\u007F])*?\1/
    STRING_MULTI = /"{3}([^\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]*?(?<!\\)"{3,5})/m
    STRING_LITERAL = /(['])(?:\\?[^\u0000-\u0008\u000A-\u001F\u007F])*?\1/
    STRING_LITERAL_MULTI = /'{3}([^\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]*?'{3,5})/m
    DATETIME = /(-?\d{4})-(\d{2})-(\d{2})(?:(?:t|\s)(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?))?(z|[-+]\d{2}:\d{2})?/i
    LOCAL_TIME = /(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)/
    FLOAT = /[+-]?(?:(?:\d|[1-9](?:_?\d)*)\.\d(?:_?\d)*|\d+(?=[eE]))(?:[eE][+-]?[0-9]+(_[0-9])*[0-9]*)?(?!\w)/
    FLOAT_KEYWORD = /[+-]?(?:inf|nan)\b/
    INTEGER = /[+-]?([1-9](_?\d)*|0)(?![A-Za-z0-9_-]+)/
    NON_DEC_INTEGER = /0(?:x[0-9A-Fa-f]+(?:_[0-9A-Fa-f])*[0-9A-Fa-f]*|o[0-7]+(?:_[0-7])*[0-7]*|b[01]+(?:_[01])*[01]*)/
    BOOLEAN = /true|false/
    SPACED_ARRAY_OF_TABLES_START = /^\[[ \t]+\[(#{IDENTIFIER}|#{STRING_BASIC}|#{STRING_LITERAL}|#{INTEGER}|#{NON_DEC_INTEGER}|#{FLOAT_KEYWORD}|#{BOOLEAN})\]\]$/
    SPACED_ARRAY_OF_TABLES_END = /^\[\[(#{IDENTIFIER}|#{STRING_BASIC}|#{STRING_LITERAL}|#{INTEGER}|#{NON_DEC_INTEGER}|#{FLOAT_KEYWORD}|#{BOOLEAN})\][ \t]+\]$/
    SPACED_ARRAY_OF_TABLES_BOTH = /^\[[ \t]+\[(#{IDENTIFIER}|#{STRING_BASIC}|#{STRING_LITERAL}|#{INTEGER}|#{NON_DEC_INTEGER}|#{FLOAT_KEYWORD}|#{BOOLEAN})\][ \t]+\]$/

    def initialize(io)
      @ss = StringScanner.new(io.read)
      @eos = false
    end

    def next_token
      case
      when @ss.scan(NEWLINE) then [:NEWLINE, nil]
      when @ss.scan(SPACED_ARRAY_OF_TABLES_START) then raise ParseError.new("Array of tables has spaces in starting brackets")
      when @ss.scan(SPACED_ARRAY_OF_TABLES_END) then raise ParseError.new("Array of tables has spaces in ending brackets")
      when @ss.scan(SPACED_ARRAY_OF_TABLES_BOTH) then raise ParseError.new("Array of tables has spaces in starting and ending brackets")
      when @ss.scan(SPACE) then next_token
      when @ss.scan(COMMENT) then next_token
      when @ss.scan(DATETIME) then process_datetime
      when @ss.scan(LOCAL_TIME) then process_local_time
      when text = @ss.scan(STRING_MULTI) then [:STRING_MULTI, text[3..-4]]
      when text = @ss.scan(STRING_BASIC) then [:STRING_BASIC, text[1..-2]]
      when text = @ss.scan(STRING_LITERAL_MULTI) then [:STRING_LITERAL_MULTI, text[3..-4]]
      when text = @ss.scan(STRING_LITERAL) then [:STRING_LITERAL, text[1..-2]]
      when text = @ss.scan(FLOAT) then [:FLOAT, text]
      when text = @ss.scan(FLOAT_KEYWORD) then [:FLOAT_KEYWORD, text]
      when text = @ss.scan(INTEGER) then [:INTEGER, text]
      when text = @ss.scan(NON_DEC_INTEGER) then [:NON_DEC_INTEGER, text]
      when text = @ss.scan(BOOLEAN) then [:BOOLEAN, text]
      when text = @ss.scan(IDENTIFIER) then [:IDENTIFIER, text]
      when @ss.eos? then process_eos
      else x = @ss.getch; [x, x]
      end
    end

    def process_datetime
      if @ss[7]
        offset = @ss[7].gsub(/[zZ]/, '+00:00')
      end
      args = [@ss[1], @ss[2], @ss[3], @ss[4], @ss[5], @ss[6], offset]
      [:DATETIME, args]
    end

    def process_local_time
      args = [@ss[1], @ss[2], @ss[3].to_f]
      [:LOCAL_TIME, args]
    end

    def process_eos
      return if @eos

      @eos = true
      [:EOS, nil]
    end
  end
end
