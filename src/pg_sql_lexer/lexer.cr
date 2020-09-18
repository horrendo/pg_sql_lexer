require "./token"
require "./keyword"
require "./exceptions"

module PgSqlLexer
  alias Tokens = Array(Token)

  class Lexer
    getter tokens : Tokens = [] of Token
    @pos : Int32 = 0
    @eos : Int32

    def initialize(@buffer : String, @use_reserved_keywords = true, @use_non_reserved_keywords = false)
      @eos = @buffer.size - 1
      scan
    end

    def scan : Nil
      return @tokens if @buffer.size == 0
      loop do
        break unless next_token
      end
      return @tokens
    end

    def next_token : Bool
      case c = current_char
      when '\0' then return false
      when ' ', '\n', '\t'
      when '(' then @tokens << Token.new(:"(")
      when ')' then @tokens << Token.new(:")")
      when '[' then @tokens << Token.new(:"[")
      when ']' then @tokens << Token.new(:"]")
      when ',' then @tokens << Token.new(:",")
      when ';'
        @tokens << Token.new(:";")
        return false
      when '"'  then quoted_identifier
      when '\'' then string_constant
      when '$'
        if (n = peek_next_char).number?
          positional_parameter
        else
          dollar_quote
        end
      when '-'
        case peek_next_char
        when '-'
          comment_to_eol
        else
          operator(c)
        end
      when '+', '*', '<', '>', '=', '~', '!', '@', '#', '%', '^', '&', '|', '`', '?'
        operator(c)
      when '/'
        case peek_next_char
        when '*'
          comment_to_star_slash
        else
          operator(c)
        end
      when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
        numeric_constant(c)
      when '.'
        if (n = peek_next_char).number?
          numeric_constant(c)
        elsif n == '.'
          current_char
          @tokens << Token.new(:"..")
        else
          @tokens << Token.new(:".")
        end
      when ':'
        if peek_next_char == c
          @pos += 1
          @tokens << Token.new(:"::")
        else
          @tokens << Token.new(:":")
        end
      when 'b', 'B'
        if peek_next_char == '\''
          binary_bit_string(c)
        else
          identifier_or_keyword(c)
        end
      when 'x', 'X'
        if peek_next_char == '\''
          hex_bit_string(c)
        else
          identifier_or_keyword(c)
        end
      when 'u', 'U'
        if peek_next_char == '&'
          case peek_next_char(1)
          when '"'
            current_char(1)
            quoted_identifier(true)
          when '\''
            current_char(1)
            string_constant(true)
          end
        else
          identifier_or_keyword(c)
        end
      else
        identifier_or_keyword(c) if c.letter? || c == '_'
      end
      true
    end

    def identifier_or_keyword(first_char : Char) : Nil
      token = [first_char]
      while c = current_char
        break unless c.alphanumeric? || c == '_' || c == '$'
        token << c
      end
      @pos -= 1 unless c == '\0'
      ident = token.join
      @tokens << Token.new(
        Keyword.is_keyword(ident, @use_reserved_keywords, @use_non_reserved_keywords) ? :keyword : :identifier,
        ident)
    end

    def operator(first_char : Char) : Nil
      token = [first_char]
      while c = current_char
        case c
        when '-'
          raise InvalidOperator.new if token[-1] == '-'
        when '*'
          raise InvalidOperator.new if token[-1] == '/'
        when '+', '/', '<', '>', '=', '~', '!', '@', '#', '%', '^', '&', '|', '`', '?'
        else
          @pos -= 1 unless c == '\0'
          break
        end
        token << c
      end
      if token.size > 1 && ((token[-1] == '+') || (token[-1] == '-'))
        found = false
        ['~', '!', '@', '#', '%', '^', '&', '|', '`', '?'].each do |r|
          if token.index(r)
            found = true
            break
          end
        end
        raise InvalidOperator.new unless found
      end
      @tokens << Token.new(:operator, token.join)
    end

    def hex_bit_string(first_char : Char) : Nil
      token = [first_char, '\'']
      @pos += 1
      while (c = current_char) != '\''
        if c.hex?
          token << c
        else
          raise InvalidHexBitString.new
        end
      end
      token << c
      @tokens << Token.new(:hex_bit_string, token.join)
    end

    def binary_bit_string(first_char : Char) : Nil
      token = [first_char, '\'']
      @pos += 1
      while (c = current_char) != '\''
        case c
        when '0', '1'
          token << c
        else
          raise InvalidBinaryBitString.new
        end
      end
      token << c
      @tokens << Token.new(:binary_bit_string, token.join)
    end

    def positional_parameter : Nil
      token = ['$']
      while c = current_char
        if c.number?
          token << c
        else
          @pos -= 1 unless c == '\0'
          break
        end
      end
      @tokens << Token.new(:positional_parameter, token.join)
    end

    def dollar_quote : Nil
      token = ['$']
      first = true
      got_ident = false
      got_possible_ident = false
      possible_ident_idx = 0
      ident : String = ""
      while c = current_char
        if (c == '\0') ||
           (first && !c.letter? && c != '$') ||
           !(c.alphanumeric? || c == '_' || c == '$' || got_ident)
          raise InvalidIdentifier.new
        end
        first = false
        token << c
        if c == '$'
          break if got_possible_ident && possible_ident_idx + 2 == ident.size
          if got_ident
            got_possible_ident = true
            possible_ident_idx = 0
          else
            ident = token.join
            got_ident = true
          end
        else
          if got_possible_ident
            possible_ident_idx += 1
            if ident[possible_ident_idx]? != c
              got_possible_ident = false
            end
          end
        end
      end
      @tokens << Token.new(:string_constant, token.join)
    end

    def numeric_constant(first_char : Char) : Nil
      token = [first_char]
      seen_dot = first_char == '.'
      seen_digit = first_char.number?
      seen_e = false
      while c = current_char
        if c.number?
          token << c
          seen_digit = true
        elsif c == '.'
          raise InvalidNumericLiteral.new if seen_dot
          seen_dot = true
          token << c
        elsif c == 'e'
          raise InvalidNumericLiteral.new if seen_e
          raise InvalidNumericLiteral.new unless seen_digit
          seen_e = true
          token << c
          if (c = peek_next_char) == '+' || c == '-'
            token << current_char
            if !peek_next_char.number?
              raise InvalidNumericLiteral.new
            end
          elsif !c.number?
            raise InvalidNumericLiteral.new
          end
        elsif c.letter?
          raise InvalidNumericLiteral.new
        else
          break
        end
      end
      @pos -= 1 unless c == '\0'
      @tokens << Token.new(:numeric_constant, token.join)
    end

    def string_constant(is_unicode = false) : Nil
      eos = false
      token = is_unicode ? ['u', '&'] : [] of Char
      token << '\''
      until eos
        case c = current_char
        when '\0'
          raise MissingEndQuotedLiteral.new
        when '\''
          case nxt = peek_next_char
          when '\''
            token << c
            token << c
            @pos += 1
          when ' ', '\t', '\n'
            save_pos = @pos
            seen_nl = false
            while nxt != '\''
              break if !nxt.ascii_whitespace?
              seen_nl = true if nxt == '\n'
              nxt = current_char
            end
            unless nxt == '\'' && seen_nl
              @pos = save_pos
              eos = true
            end
          else
            eos = true
          end
          token << c if eos
        else
          token << c
        end
      end
      @tokens << Token.new(:string_constant, token.join)
    end

    def quoted_identifier(is_unicode = false) : Nil
      got_end = false
      got_ident = false
      token = is_unicode ? ['u', '&'] : [] of Char
      token << '"'
      loop do
        case c = current_char
        when '\0'
          raise MissingEndQuotedIdentifier.new
        when '"'
          token << c
          got_end = true
          break
        end
        token << c
        got_ident = true unless got_ident
      end
      raise MissingEndQuotedIdentifier.new unless got_end
      raise NoZeroLengthQuotedIdentifier.new unless got_ident
      @tokens << Token.new(:quoted_identifier, token.join)
    end

    def comment_to_star_slash : Nil
      token = [] of Char
      c = current_char # skip over '*'
      got_end = false
      loop do
        case c = current_char
        when '\0'
          raise MissingEndComment.new
        when '*'
          case peek_next_char
          when '\0'
            raise MissingEndComment.new
          when '/'
            current_char # consume final '/'
            got_end = true
            break
          end
        end
        token << c
      end
      raise MissingEndComment.new unless got_end
      @tokens << Token.new(:comment, token.join.strip.gsub(/\s+/, ' '))
    end

    def comment_to_eol : Nil
      token = [] of Char
      c = current_char # skip over 2nd '-'
      loop do
        case c = current_char
        when '\0', '\n'
          break
        else
          token << c
        end
      end
      @tokens << Token.new(:comment, token.join.strip.gsub(/\s{2,}/, ' '))
    end

    def current_char(skip = 0) : Char
      @pos += skip if skip > 0
      if @pos <= @eos
        c = @buffer[@pos]
        @pos += 1
        return c
      end
      '\0'
    end

    def peek_next_char(offset : Int32 = 0) : Char
      if (pos = @pos + offset) <= @eos
        @buffer[pos]
      else
        '\0'
      end
    end
  end
end
