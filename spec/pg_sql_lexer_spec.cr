require "./spec_helper"

describe PgSqlLexer do
  describe "Lexer" do
    it "returns an empty array of tokens for an empty string" do
      tokens = PgSqlLexer::Lexer.new("").tokens
      tokens.size.should eq(0)
    end

    it "correctly identifies a to-eol comment token" do
      ["hello world", " hello world", "  hello world", "hello  world", "hello world "].each do |s|
        tokens = PgSqlLexer::Lexer.new("--#{s}").tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:comment)
        tokens[0].value.should eq("hello world")
      end
    end

    it "detects a missing end comment" do
      ["/*", "/* *", "/* * /", "/*  ", "/* *\n/"].each do |s|
        expect_raises(PgSqlLexer::MissingEndComment) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a slash-star comment token" do
      ["hello world",
       " hello world ",
       "  hello world",
       "hello  world",
       "hello world ",
       "hello\nworld",
       "\n hello\n world\n",
      ].each do |s|
        tokens = PgSqlLexer::Lexer.new("/*#{s}*/").tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:comment)
        tokens[0].value.should eq("hello world")
      end
    end

    it "correctly identifies special character tokens" do
      ["(", ")", ":", "::", "[", "]", ",", ";", "."].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
      end
    end

    it "detects an invalid operator" do
      ["#--", "#/*", "*-", "*+"].each do |s|
        expect_raises(PgSqlLexer::InvalidOperator) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies an operator" do
      ["+", "*", "/", "<", ">", "=", "~", "!", "@", "#", "%", "^", "&", "|", "`", "?", "<=", ">=", "@-", "%+"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:operator)
        tokens[0].value.should eq(s)
      end
    end

    it "detects a missing end to a quoted identifier" do
      ["", " ", "aaa", " aaa", " a ", "a  "].each do |s|
        expect_raises(PgSqlLexer::MissingEndQuotedIdentifier) do
          PgSqlLexer::Lexer.new(%("#{s})).tokens
        end
      end
    end

    it "detects a zero length quoted identifier" do
      expect_raises(PgSqlLexer::NoZeroLengthQuotedIdentifier) do
        PgSqlLexer::Lexer.new(%("")).tokens
      end
    end

    it "correctly identifies quoted identifier tokens" do
      ["a", " ", "hello", "hello world"].each do |s|
        tokens = PgSqlLexer::Lexer.new(%("#{s}")).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:quoted_identifier)
        tokens[0].value.should eq(%("#{s}"))
      end
    end

    it "correctly identifies unicode quoted identifier tokens" do
      ["a", " ", "hello", "hello world", "\\0441\\043B\\043E\\043D", "d\\0061t\\+000061"].each do |s|
        tokens = PgSqlLexer::Lexer.new(%(u&"#{s}")).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:quoted_identifier)
        tokens[0].value.should eq(%(u&"#{s}"))
      end
    end

    it "detects a missing closing quote for a string constant" do
      ["'", "' ", "'aaa", "' aaa", "' a ", "'a  ", "'a' \n'bc"].each do |s|
        expect_raises(PgSqlLexer::MissingEndQuotedLiteral) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a string constant" do
      ["''", "'a'", "' '", "'abc'"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:string_constant)
        tokens[0].value.should eq(s)
      end
    end

    it "correctly identifies and combines a multi-line string constant" do
      ["'abc'\n'def'", "'abc'  \n'def'", "'ab'\n'cd'\n'ef'", "'a'  \n  'b'\n  'c'  \n  'def'"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:string_constant)
        tokens[0].value.should eq("'abcdef'")
      end
    end

    it "correctly identifies unicode quoted string constant" do
      ["a", " ", "hello", "hello world", "\\0441\\043B\\043E\\043D", "d\\0061t\\+000061"].each do |s|
        buf = "u&'#{s}'"
        tokens = PgSqlLexer::Lexer.new(buf).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:string_constant)
        tokens[0].value.should eq(buf)
      end
    end

    it "detects an invalid numeric constant" do
      ["1.3.2", "1a", "123e", "0.e-a"].each do |s|
        expect_raises(PgSqlLexer::InvalidNumericLiteral) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a numeric constant" do
      ["1", "987", "0", "0.123", ".123", "123e-1", "123e+1", "123e1"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:numeric_constant)
        tokens[0].value.should eq(s)
      end
    end

    it "detects problems with a dollar-quoted string constant" do
      ["$?abc$?", "$$hello$", "$abc$hello$$", "$abc$hello$abcd$", "$a?$hello$a?$"].each do |s|
        expect_raises(PgSqlLexer::InvalidIdentifier) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a dollar-quoted string constant" do
      ["$$$$", "$$x$$", "$$\n$$", "$$abc\n\tdef\nghi$$", "$abc$hel$ablo$abc$"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:string_constant)
        tokens[0].value.should eq(s)
      end
    end

    it "correctly identifies a positional parameter" do
      ["$1", "$12", "$1234"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:positional_parameter)
        tokens[0].value.should eq(s)
      end
    end

    it "detects problems with a binary bit-string" do
      ["b'1 '", "b'02'", "b'1x'", "B'1 '", "B'02'", "B'1x'"].each do |s|
        expect_raises(PgSqlLexer::InvalidBinaryBitString) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a binary bit-string" do
      ["b'1'", "b'0'", "B'1'", "B'0'", "b'1010101'", "b'0000000'"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:binary_bit_string)
        tokens[0].value.should eq(s)
      end
    end

    it "detects problems with a hex bit-string" do
      ["x'1 '", "x'0g'", "x'1?'", "X'1 '", "X'0g'", "X'1?'"].each do |s|
        expect_raises(PgSqlLexer::InvalidHexBitString) do
          PgSqlLexer::Lexer.new(s).tokens
        end
      end
    end

    it "correctly identifies a hex bit-string" do
      ["x'0'", "x'1'", "x'e'", "x'f'", "x'1f'", "x'ff'", "X'0'", "X'1'", "X'e'", "X'f'", "X'1f'", "X'ff'"].each do |s|
        tokens = PgSqlLexer::Lexer.new(s).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:hex_bit_string)
        tokens[0].value.should eq(s)
      end
    end

    it "correctly identifies keywords" do
      %w(select where with Primary CREATE order where and or TiMeStAmP).each do |w|
        tokens = PgSqlLexer::Lexer.new(w).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:keyword)
        tokens[0].value.should eq(w)
      end
    end

    it "correctly identifies identifiers" do
      %w(customer employee manager customer_id created_ts).each do |w|
        tokens = PgSqlLexer::Lexer.new(w).tokens
        tokens.size.should eq(1)
        tokens[0].type.should eq(:identifier)
        tokens[0].value.should eq(w)
      end
    end

    it "correctly identifies tokens in a multi-word string" do
      tokens = PgSqlLexer::Lexer.new("select   *\nfrom\tcustomer\nwhere (id > 10) or (customer_name like 'numpty%')").tokens
      tokens.size.should eq(16)
      tokens[0].type.should eq(:keyword)
      tokens[0].value.should eq("select")
      tokens[1].type.should eq(:operator)
      tokens[1].value.should eq("*")
      tokens[2].type.should eq(:keyword)
      tokens[2].value.should eq("from")
      tokens[3].type.should eq(:identifier)
      tokens[3].value.should eq("customer")
      tokens[4].type.should eq(:keyword)
      tokens[4].value.should eq("where")
      tokens[5].type.should eq(:"(")
      tokens[5].value.should be_nil
      tokens[6].type.should eq(:identifier)
      tokens[6].value.should eq("id")
      tokens[7].type.should eq(:operator)
      tokens[7].value.should eq(">")
      tokens[8].type.should eq(:numeric_constant)
      tokens[8].value.should eq("10")
      tokens[9].type.should eq(:")")
      tokens[9].value.should be_nil
      tokens[10].type.should eq(:keyword)
      tokens[10].value.should eq("or")
      tokens[11].type.should eq(:"(")
      tokens[11].value.should be_nil
      tokens[12].type.should eq(:identifier)
      tokens[12].value.should eq("customer_name")
      tokens[13].type.should eq(:keyword)
      tokens[13].value.should eq("like")
      tokens[14].type.should eq(:string_constant)
      tokens[14].value.should eq("'numpty%'")
      tokens[15].type.should eq(:")")
      tokens[15].value.should be_nil
    end
  end
end
