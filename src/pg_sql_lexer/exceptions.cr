module PgSqlLexer
  # An exception that is raised if the closing `*/` is not found for
  # a comment
  class MissingEndComment < Exception
    def initialize
      super("missing end of /* comment")
    end
  end

  # An exception that is raised if the closing `"` is not found for
  # a double-quoted identifier
  class MissingEndQuotedIdentifier < Exception
    def initialize
      super("missing end of double quoted identifier")
    end
  end

  # An exception that is raised if the closing `'` is not found for
  # a string literal
  class MissingEndQuotedLiteral < Exception
    def initialize
      super("missing end of quoted string literal")
    end
  end

  # An exception that is raised if two consecutive `"` characters
  # are encountered
  class NoZeroLengthQuotedIdentifier < Exception
    # :nodoc:
    def initialize
      super("length of double quoted identifier must be > 0")
    end
  end

  # An exception that is raised if the closing */ is not found for
  # a comment
  class InvalidNumericLiteral < Exception
    # :nodoc:
    def initialize
      super("Invalid numeric literal")
    end
  end

  # An exception that is raised if non-numeric characters are encountered
  # while parsing a numeric literal
  class InvalidIdentifier < Exception
    # :nodoc:
    def initialize
      super("Invalid identifier")
    end
  end

  # An exception that is raised if non-binary characters are encountered
  # while parsing a binary bit-string literal
  class InvalidBinaryBitString < Exception
    # :nodoc:
    def initialize
      super("Invalid binary bit-string")
    end
  end

  # An exception that is raised if non-hexidecimal characters are encountered
  # while parsing a hexidecimal  bit-string literal
  class InvalidHexBitString < Exception
    # :nodoc:
    def initialize
      super("Invalid hexidecimal bit-string")
    end
  end

  # An exception that is raised if an invalid character is encountered
  # while parsing an operator, or the resulting operator violates
  # postgres naming rules
  class InvalidOperator < Exception
    # :nodoc:
    def initialize
      super("Invalid Operator")
    end
  end
end
