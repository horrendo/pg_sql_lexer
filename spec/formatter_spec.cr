require "./spec_helper"

describe PgSqlLexer do
  describe "Formatter" do
    it "correctly minifies a statement with extra whitespace" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("\nSELECT   1\n  FROM\t\tsome_table\n;")
          .tokens)
        .format_minified.should eq("select 1 from some_table;")
    end

    it "correctly minifies a statement excluding comments" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT 1 -- Some comment\nFROM\t\tsome_table\n;")
          .tokens)
        .format_minified.should eq("select 1 from some_table;")
    end

    it "correctly minifies a statement excluding multi-line comments" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT 1\n/*\n Some comment\n*/\nFROM\t\tsome_table\n;")
          .tokens)
        .format_minified.should eq("select 1 from some_table;")
    end

    it "correctly minifies a statement including comments" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT 1 -- Some comment\nFROM\t\tsome_table\n;")
          .tokens)
        .format_minified(true).should eq("select 1 /* Some comment */ from some_table;")
    end

    it "correctly minifies a statement including multi-line comments" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT 1\n/*\n Some comment\n*/\nFROM\t\tsome_table\n;")
          .tokens)
        .format_minified(true).should eq("select 1 /* Some comment */ from some_table;")
    end

    it "correctly minifies a statement with a comma-separated list" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT  col1,col2,     col3,\ncol4 from some_table;")
          .tokens)
        .format_minified.should eq("select col1, col2, col3, col4 from some_table;")
    end

    it "correctly minifies a statement with a cast" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("SELECT  col1 :: text  ,   col2 from some_table;")
          .tokens)
        .format_minified.should eq("select col1::text, col2 from some_table;")
    end

    it "correctly minifies a statement with a cte" do
      PgSqlLexer::Formatter.new(
        PgSqlLexer::Lexer
          .new("with a as (\nselect something\n\tfrom somewhere)\nselect blah from somewhere_else\njoin a\n\ton a.id = b.id\nwhere true;")
          .tokens)
        .format_minified.should eq("with a as (select something from somewhere) select blah from somewhere_else join a on a.id = b.id where true;")
    end
  end
end
