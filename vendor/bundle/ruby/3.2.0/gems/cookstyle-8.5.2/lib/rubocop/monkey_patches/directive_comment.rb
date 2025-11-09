# frozen_string_literal: true
module RuboCop
  # we're monkey patching the config regex to allow for "cookstyle: disable whatever"
  # in addition to the "rubocop: disable whatever that comes with RuboCop"
  class DirectiveComment
    remove_const(:DIRECTIVE_COMMENT_REGEXP)
    DIRECTIVE_COMMENT_REGEXP = Regexp.new(
      "# (?:rubocop|cookstyle) : ((?:disable|enable|todo))\\b #{COPS_PATTERN}"
        .gsub(' ', '\s*')
    )
  end
end
