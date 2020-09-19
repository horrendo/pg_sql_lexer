# pg_sql_lexer

I needed a way to 'minify' SQL statements in another crystal project. This turned out to be quite tricky so I figured the easiest way was to create a simple lexer and use the tokens to generate a minified representation. This lexer is also written in Crystal (obviously) 😀.

[![Build Status](https://travis-ci.org/horrendo/pg_sql_lexer.svg?branch=master)](https://travis-ci.org/horrendo/pg_sql_lexer)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lexpgsql:
       github: horrendo/pg_sql_lexer
   ```

2. Run `shards install`

## Usage

```crystal
require "pg_sql_lexer"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/horrendo/pg_sql_lexer/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Steve Baldwin](https://github.com/horrendo) - creator and maintainer
