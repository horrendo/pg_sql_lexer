module PgSqlLexer
  #
  # This class defines two collections of keywords. The [Postgres Docs](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS) define
  # a category of lexical element - 'Identifiers and Keywords'. Syntactically they are very similar so it is
  # not always easy to distinguish between them. In writing this library I didn't actually need to
  # distinguish but I recognise someone elses needs may differ. Postgres makes the keywords available
  # from the builtin function `pg_get_keywords`. For example:
  #
  # ```sql
  # b2bc_dev=# select * from pg_get_keywords();
  #        word        | catcode |                   catdesc
  # -------------------+---------+----------------------------------------------
  #  abort             | U       | unreserved
  #  absolute          | U       | unreserved
  #  access            | U       | unreserved
  #  action            | U       | unreserved
  #  add               | U       | unreserved
  #  admin             | U       | unreserved
  #  after             | U       | unreserved
  #  aggregate         | U       | unreserved
  #  all               | R       | reserved
  #  :
  # ```
  # The `reserved` set of keywords is defined by the query `select word from pg_get_keywords() where catcode != 'U'`.
  #
  # The `non-reserved` set of keywords is defined by the query `select word from pg_get_keywords() where catcode = 'U'`.
  #
  # This class is not typically accessed directly, but is used by the `Lexer` class. The constructor
  # for the `Lexer` class allows you to control which set or sets of keywords are used during the
  # parsing process. This will control whether a `Token` has a `type` of `:keyword` or `:identifier`.
  #
  class Keyword
    #
    # Source: select string_agg(word, ' ') from pg_get_keywords() where catcode != 'U';
    #
    @@reserved : Set(String) = %w(
      all analyse analyze and any array as asc asymmetric authorization between bigint binary bit
      boolean both case cast character check collate collation column concurrently constraint create
      cross current_catalog current_date current_role current_schema current_time current_timestamp
      current_user dec decimal default deferrable desc distinct do else end except exists extract
      false fetch float for foreign freeze from full grant group grouping having ilike in initially
      inner inout int integer intersect interval into is isnull join lateral leading least left like
      limit localtime localtimestamp national natural nchar none not notnull null nullif numeric offset
      on only or order out outer overlaps overlay placing position precision primary real references
      returning right row select session_user setof similar smallint some symmetric table tablesample
      then time timestamp to trailing treat trim true union unique user using values variadic verbose
      when where window with xmlattributes xmlconcat xmlelement xmlexists xmlforest xmlnamespaces
      xmlparse xmlpi xmlroot xmlserialize xmltable
    ).to_set

    #
    # Source: select string_agg(word, ' ') from pg_get_keywords() where catcode = 'U';
    #
    @@non_reserved : Set(String) = %w(
      abort absolute access action add admin after aggregate also alter always assertion assignment
      at attach attribute backward before begin by cache call called cascade cascaded catalog chain char
      characteristics checkpoint class close cluster coalesce columns comment comments commit committed
      configuration conflict connection constraints content continue conversion copy cost csv cube
      current cursor cycle data database day deallocate declare defaults deferred definer delete
      delimiter delimiters depends detach dictionary disable discard document domain double drop each
      enable encoding encrypted enum escape event exclude excluding exclusive execute explain extension
      external family filter first following force forward function functions generated global granted
      greatest groups handler header hold hour identity if immediate immutable implicit import include including
      increment index indexes inherit inherits inline input insensitive insert instead invoker
      isolation key label language large last leakproof level listen load local location lock locked
      logged mapping match materialized maxvalue method minute minvalue mode month move name names new
      next no nothing notify nowait nulls object of off oids old operator option options ordinality
      others over overriding owned owner parallel parser partial partition passing password plans policy
      preceding prepare prepared preserve prior privileges procedural procedure procedures program
      publication quote range read reassign recheck recursive ref referencing refresh reindex relative
      release rename repeatable replace replica reset restart restrict returns revoke role rollback
      rollup routine routines rows rule savepoint schema schemas scroll search second security sequence
      sequences serializable server session set sets share show simple skip snapshot sql stable
      standalone start statement statistics stdin stdout storage stored strict strip subscription
      substring support sysid system tables tablespace temp template temporary text ties transaction transform
      trigger truncate trusted type types unbounded uncommitted unencrypted unknown unlisten unlogged
      until update vacuum valid validate validator value varchar varying version view views volatile whitespace
      within without work wrapper write xml year yes zone
    ).to_set

    # :nodoc:
    def self.is_keyword(s : String, reserved = true, non_reserved = false) : Bool
      (reserved && @@reserved.includes?(s.downcase)) || (non_reserved && @@non_reserved.includes?(s.downcase))
    end
  end
end
