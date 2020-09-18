module Lexpgsql
  class MissingEndComment < Exception
    def initialize
      super("missing end of /* comment")
    end
  end

  class MissingEndQuotedIdentifier < Exception
    def initialize
      super("missing end of double quoted identifier")
    end
  end

  class MissingEndQuotedLiteral < Exception
    def initialize
      super("missing end of quoted string literal")
    end
  end

  class NoZeroLengthQuotedIdentifier < Exception
    def initialize
      super("length of double quoted identifier must be > 0")
    end
  end

  class InvalidNumericLiteral < Exception
    def initialize
      super("Invalid numeric literal")
    end
  end

  class InvalidIdentifier < Exception
    def initialize
      super("Invalid identifier")
    end
  end

  class InvalidBinaryBitString < Exception
    def initialize
      super("Invalid binary bit-string")
    end
  end

  class InvalidHexBitString < Exception
    def initialize
      super("Invalid hexidecimal bit-string")
    end
  end

  class InvalidSyntax < Exception
    def initialize
      super("Syntax error")
    end
  end

  class InvalidOperator < Exception
    def initialize
      super("Invalid Operator")
    end
  end
end
