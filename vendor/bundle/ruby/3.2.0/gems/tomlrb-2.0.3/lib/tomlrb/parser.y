class Tomlrb::GeneratedParser
token IDENTIFIER STRING_MULTI STRING_BASIC STRING_LITERAL_MULTI STRING_LITERAL DATETIME LOCAL_TIME INTEGER NON_DEC_INTEGER FLOAT FLOAT_KEYWORD BOOLEAN NEWLINE EOS
rule
  expressions
    | expressions expression
    | expressions EOS
    ;
  expression
    : table
    | assignment
    | inline_table
    | NEWLINE
    ;
  table
    : table_start table_continued NEWLINE
    | table_start table_continued EOS
    ;
  table_start
    : '[' '[' { @handler.start_(:array_of_tables) }
    | '[' { @handler.start_(:table) }
    ;
  table_continued
    : ']' ']' { array = @handler.end_(:array_of_tables); @handler.set_context(array, is_array_of_tables: true) }
    | ']' { array = @handler.end_(:table); @handler.set_context(array) }
    | table_identifier table_next
    ;
  table_next
    : ']' ']' { array = @handler.end_(:array_of_tables); @handler.set_context(array, is_array_of_tables: true) }
    | ']' { array = @handler.end_(:table); @handler.set_context(array) }
    | '.' table_continued
    ;
  table_identifier
    : table_identifier '.' table_identifier_component { @handler.push(val[2]) }
    | table_identifier '.' FLOAT { val[2].split('.').each { |k| @handler.push(k) } }
    | FLOAT {
      keys = val[0].split('.')
      @handler.start_(:table)
      keys.each { |key| @handler.push(key) }
    }
    | table_identifier_component { @handler.push(val[0]) }
    ;
  table_identifier_component
    : IDENTIFIER
    | STRING_BASIC { result = StringUtils.replace_escaped_chars(val[0]) }
    | STRING_LITERAL
    | INTEGER
    | NON_DEC_INTEGER
    | FLOAT_KEYWORD
    | BOOLEAN
    ;
  inline_table
    : inline_table_start inline_table_end
    | inline_table_start inline_continued inline_table_end
    ;
  inline_table_start
    : '{' { @handler.start_(:inline) }
    ;
  inline_table_end
    : '}' {
      array = @handler.end_(:inline)
      @handler.push_inline(array)
    }
    ;
  inline_continued
    : inline_assignment
    | inline_assignment inline_next
    ;
  inline_next
    : ',' inline_continued
    ;
  inline_assignment
    : inline_assignment_key '=' value {
      keys = @handler.end_(:inline_keys)
      @handler.push(keys)
    }
    ;
  inline_assignment_key
    : inline_assignment_key '.' assignment_key_component { 
      @handler.push(val[2]) 
    }
    | inline_assignment_key '.' FLOAT { val[2].split('.').each { |k| @handler.push(k) } }
    | FLOAT {
      keys = val[0].split('.')
      @handler.start_(:inline_keys)
      keys.each { |key| @handler.push(key) }
    }
    | assignment_key_component { 
      @handler.start_(:inline_keys) 
      @handler.push(val[0]) 
    }
    ;
  assignment
    : assignment_key '=' value EOS {
      keys = @handler.end_(:keys)
      value = keys.pop
      @handler.validate_value(value)
      @handler.push(value)
      @handler.assign(keys)
    }
    | assignment_key '=' value NEWLINE {
      keys = @handler.end_(:keys)
      value = keys.pop
      @handler.validate_value(value)
      @handler.push(value)
      @handler.assign(keys)
    }
    ;
  assignment_key
    : assignment_key '.' assignment_key_component { @handler.push(val[2]) }
    | assignment_key '.' FLOAT { val[2].split('.').each { |k| @handler.push(k) } }
    | FLOAT {
      keys = val[0].split('.')
      @handler.start_(:keys)
      keys.each { |key| @handler.push(key) }
    }
    | assignment_key_component { @handler.start_(:keys); @handler.push(val[0]) }
    ;
  assignment_key_component
    : IDENTIFIER
    | STRING_BASIC { result = StringUtils.replace_escaped_chars(val[0]) }
    | STRING_LITERAL
    | INTEGER
    | NON_DEC_INTEGER
    | FLOAT_KEYWORD
    | BOOLEAN
    ;
  array
    : start_array array_continued
    ;
  array_continued
    : ']' { array = @handler.end_(:array); @handler.push(array.compact) }
    | value array_next
    | NEWLINE array_continued
    ;
  array_next
    : ']' { array = @handler.end_(:array); @handler.push(array.compact) }
    | ',' array_continued
    | NEWLINE array_continued
    ;
  start_array
    : '[' { @handler.start_(:array) }
    ;
  value
    : scalar { @handler.push(val[0]) }
    | array
    | inline_table
    ;
  scalar
    : string
    | literal
    ;
  literal
    | FLOAT { result = val[0].to_f }
    | FLOAT_KEYWORD {
      v = val[0]
      result = if v.end_with?('nan')
                 Float::NAN
               else
                 (v[0] == '-' ? -1 : 1) * Float::INFINITY
               end
    }
    | INTEGER { result = val[0].to_i }
    | NON_DEC_INTEGER {
      base = case val[0][1]
             when "x" then 16
             when "o" then 8
             when "b" then 2
             end
      result = val[0].to_i(base)
    }
    | BOOLEAN { result = val[0] == 'true' ? true : false }
    | DATETIME {
      v = val[0]
      result = if v[6].nil?
                 if v[4].nil?
                   LocalDate.new(v[0], v[1], v[2])
                 else
                   LocalDateTime.new(v[0], v[1], v[2], v[3] || 0, v[4] || 0, v[5].to_f)
                 end
               else
                 # Patch for 24:00:00 which Ruby parses
                 if v[3].to_i == 24 && v[4].to_i == 0 && v[5].to_i == 0
                   v[3] = (v[3].to_i + 1).to_s
                 end

                 Time.new(v[0], v[1], v[2], v[3] || 0, v[4] || 0, v[5].to_f, v[6])
               end
    }
    | LOCAL_TIME { result = LocalTime.new(*val[0]) }
    ;
  string
    : STRING_MULTI { result = StringUtils.replace_escaped_chars(StringUtils.multiline_replacements(val[0])) }
    | STRING_BASIC { result = StringUtils.replace_escaped_chars(val[0]) }
    | STRING_LITERAL_MULTI { result = StringUtils.strip_spaces(val[0]) }
    | STRING_LITERAL { result = val[0] }
    ;
