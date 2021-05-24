# VegaLite

[![Actions Status](https://github.com/elixir-nx/vega_lite/workflows/Test/badge.svg)](https://github.com/elixir-nx/vega_lite/actions)
[![Docs](https://img.shields.io/badge/docs-gray.svg)](https://static.jonatanklosko.com/docs/vega_lite)

**Note: This is currently experimental.**

Elixir bindings to [Vega-Lite](https://vega.github.io/vega-lite).

## Installation

You can add VegaLite as a dependency in your mix.exs. At the moment
you will have to use a Git dependency until we publish the first release:

```elixir
def deps do
  [
    {:vega_lite, "~> 0.1.0-dev", github: "elixir-nx/vega_lite", branch: "main"}
  ]
end
```

You most likely want to use VegaLite in [Livebook](https://github.com/elixir-nx/livebook),
in which case you can call `Mix.install/2`:

```elixir
Mix.install([
  {:vega_lite, "~> 0.1.0-dev", github: "elixir-nx/vega_lite", branch: "main"}
])
```

## License

Copyright (C) 2021 Dashbit

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
