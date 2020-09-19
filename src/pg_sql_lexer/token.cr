module PgSqlLexer
  #
  # Defines a token encountered while parsing an SQL string. A token has the following properties:
  # * `type` - A `Symbol` describing the type of the token
  # * `value` - A `String` containing the value of the token from the source string. Not every token type has a value.
  #
  # The following token types are defined:
  #
  # `value` property populated
  # * `:keyword`
  # * `:identifier`
  # * `:operator`
  # * `:string_constant`
  # * `:numeric_constant`
  # * `:quoted_identifier`
  # * `:positional_parameter`
  # * `:binary_bit_string`
  # * `:hex_bit_string`
  # * `:comment` (Minified whitespace and multi-line comments are collapsed)
  #
  # `value` property `nil`
  # * `:"("`
  # * `:")"`
  # * `:"["`
  # * `:"]"`
  # * `:","`
  # * `:";"`
  # * `:".."`
  # * `:"."`
  # * `:"::"`
  # * `:":"`
  #
  class Token
    # :nodoc:
    property type : Symbol
    # :nodoc:
    property value : String | Nil

    # :nodoc:
    def initialize(@type, @value = nil)
    end
  end
end
