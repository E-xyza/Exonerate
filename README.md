# Exonerate

**A JSONSchema -> Elixir compiler**

## JsonSchema support scope:

Currently supports JSONSchema drafts 4, 6, 7, 2019, 2020.  *except:*

- multipleOf is not supported for number types.  This is because
  elixir does not support a floating point remainder guard, and also
  because it is impossible for a floating point to guarantee sane results
  (e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
- id fields with fragments in their uri identifier
- dynamicRefs and anchors.
- contentMediaType, contentEncoding:

  Because Exonerate doesn't return the validated structured data, validating based
  on these filters will likely require a costly decode/parse step whose results will
  be immediately thrown away.

- dictionaries

Note:

- by default, ALL strings are considered to be invalid unless they are valid
  UTF-8 encodings and will be validated.  If you require a raw binary, for example
  if you are ingesting raw data in `multipart/form-encoded`, use the
  `{"format": "binary"}` filter on your string.

## Installation

Add the following lines to your mix.exs

```elixir
  defp deps do
    [
      {:exonerate, "~> 0.3", runtime: false},
    ]
  end
```

## Quick Start

```elixir
defmodule SchemaModule do
  require Exonerate

  Exonerate.function_from_string(:def, :validate_input, """
  {
    "type":"object",
    "properties":{
      "parameter":{"type":"integer"}
    }
  }
  """)
end
```

```elixir
iex> SchemaModule.validate_input("some string")
{:error, error_value: "some string", instance_location: "/", absolute_keyword_location: "#/type"}

iex> SchemaModule.validate_input(%{"parameter" => "2"})
{:error, error_value: "2", instance_location: "/parameter", absolute_keyword_location: "#/properties/parameter/type"}

iex> SchemaModule.validate_input(%{"parameter" => 2})
:ok
```

## Licensing notes

This software contains verbatim code from https://github.com/json-schema-org/JSON-Schema-Test-Suite
which is copyright Julian Berman, et. al, and released under the MIT license.
