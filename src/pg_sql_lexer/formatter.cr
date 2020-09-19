require "./token"

module PgSqlLexer
  #
  # This class converts an array of `Token` objects produced by a `Lexer` into a formatted string.
  # Currently the only method is to produce a 'minified' format, but at some point this may be
  # expanded to other formats. Typical usage:
  # ```
  # raw_sql = {slurp from a file maybe}
  # minified = PgSqlLexer::Formatter.new(PgSqlLexer::Lexer.new(raw_sql).tokens).format_minified
  # :
  # ```
  class Formatter
    def initialize(@tokens : Array(Token))
    end

    #
    # This method takes a collection of tokens and outputs a 'minified' version of the SQL.
    #
    # The 'reconstituted' SQL is formatted on a single line (i.e. no newlines) and with no
    # more than one space between tokens. Sometimes there is no space between tokens (e.g.
    # if the previous token is a `(`).
    #
    # For example (from test suite):
    # ```
    # it "correctly minifies a statement excluding multi-line comments" do
    #   PgSqlLexer::Formatter.new(
    #     PgSqlLexer::Lexer
    #       .new("SELECT 1\n/*\n Some comment\n*/\nFROM\t\tsome_table\n;")
    #       .tokens)
    #     .format_minified.should eq("select 1 from some_table;")
    # end
    # ```
    #
    def format_minified(include_comments = false) : String
      String.build do |s|
        prev_type = :unknown
        @tokens.each_with_index do |t, i|
          no_space =
            prev_type == :"(" ||
              prev_type == :"[" ||
              prev_type == :"::" ||
              prev_type == :":" ||
              prev_type == :"." ||
              prev_type == :unknown
          if t.type == :comment
            next unless include_comments
            s << ' ' unless i == 0
            s << "/* "
            s << t.value
            s << " */"
          elsif t.type == :")"
            s << ')'
          elsif t.type == :"]"
            s << ']'
          elsif t.type == :";"
            s << ';'
          elsif t.type == :","
            s << ','
          elsif t.type == :"::"
            s << "::"
          elsif t.type == :":"
            s << ':'
          elsif t.type == :"."
            s << '.'
          elsif t.type == :"("
            s << ' ' unless no_space || prev_type == :identifier
            s << '('
          elsif t.type == :"["
            s << ' ' unless no_space
            s << '['
          elsif t.type == :keyword || t.type == :identifier
            s << ' ' unless no_space
            s << t.value.try &.downcase
          else
            s << ' ' unless no_space
            s << t.value
          end
          prev_type = t.type
        end
      end
    end
  end
end
