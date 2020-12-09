# Sparrow [![Build Status](https://img.shields.io/travis/ExpressApp/sparrow.svg)](https://travis-ci.org/ExpressApp/sparrow) [![Hex.pm](https://img.shields.io/hexpm/v/sparrow.svg)](https://hex.pm/packages/sparrow) [![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/sparrow/) [![Total Download](https://img.shields.io/hexpm/dt/sparrow.svg)](https://hex.pm/packages/sparrow) [![License](https://img.shields.io/hexpm/l/sparrow.svg)](https://hex.pm/packages/sparrow) [![Last Updated](https://img.shields.io/github/last-commit/ExpressApp/sparrow.svg)](https://github.com/ExpressApp/sparrow/commits/master)

---

Sentry client for Elixir based on the new Erlang's [logger](http://erlang.org/doc/man/logger.html). Requires Erlang 21.0 and Elixir 1.7 and later.

---

* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)

---

## Features

* Listen for events in [logger](http://erlang.org/doc/man/logger.html) (instead of deprecated [error_logger](http://erlang.org/doc/man/error_logger.html) and [Logger](https://hexdocs.pm/logger/Logger.html));
* Uses [reducers](/lib/sparrow/event/reducer.ex) to handle formatted erlang reports, like for [Ranch](/lib/sparrow/event/reducers/ranch.ex) (you can use your own reducers);
* Custom [HTTP client](/lib/sparrow/client/behaviour.ex) implementations via configuration (hackney by default);

---

## Installation

1.  Add `sparrrow` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:sparrow, "~> 1.0"}
      ]
    end
    ```

2.  Add configuration to your app:

    ```elixir
    # config/config.exs

    config :sparrow,
      dsn: "your_sentry_dsn",
      # optional configuration
      server_name: "server_name",
      release: "1.14.3-rc.3",
      tags: %{
        some: "of",
        your: "tags",
      }
    ```

---

## Usage

After installation and configuration, Sparrow will catch the error reports in your app. But there are some insignificant (for most of us) features that are not documented yet, like custom reducers and HTTP client.

Every `Logger.error` call captured too in Elixir 1.11.x and better, but you can disable this behaviour by providing `sparrow: false` in metadata, like:

```elixir
Logger.error("message", sparrow: false)
```

---

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
