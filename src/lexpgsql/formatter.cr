require "./token"

module Lexpgsql
  class Formatter
    def initialize(@tokens : Array(Token))
    end

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
            s << ' ' unless no_space
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
