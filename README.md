# Exonerate

**A JSONSchema -> Elixir macro**

Currently supports JSONSchema drafts 4, 6, 7, 2019, 2020.  *except:*

- integer filters do not match exact integer floating point values.
- multipleOf is not supported for number types.  This is because
elixir does not support a floating point remainder guard, and also
because it is impossible for a floating point to guarantee sane results
(e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
- 'definitions' is disabled in pre-draft-7, for now.  Please use absolute refs.

Works in progress:

- support for dynamicRef, dynamicAnchor
- support for contentMediaType
- support for contentEncoding
- support for named anchors
- better uri support
- support for more formatted strings

Note:
- by default, ALL strings are considered to be invalid unless they are valid
  UTF-8 encodings and will be validated.  If you require a raw binary, (for example
  if you are ingesting raw data in `multipart/form-encoded`, use the
  `{"format": "binary"}` filter on your string.
- some parts of the public API e.g. function_from_* options may change to better
  suit the standard.

String formatting included:
- date-time
- date
- time
- ipv4
- ipv6

## Installation

Add the following lines to your mix.exs

```elixir
  defp deps do
    [
      {:exonerate, "~> 0.1", runtime: false},
    ]
  end
```

## Quick Start

```elixir

defmodule SchemaModule do
  require Exonerate

  @doc """
  validates our input
  """
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
```
iex> SchemaModule.validate_input("some string")
{:error, schema_pointer: "#", error_value: "some string", json_pointer: "#/parameter"}}

iex> SchemaModule.validate_input(%{"parameter" => "2"})
{:error, schema_pointer: "#/properties/parameter", error_value: "2", json_pointer: "#/parameter"}}

iex> SchemaModule.validate_input(%{"parameter" => 2})
:ok

```

## Licensing notes

This software contains verbatim code from https://github.com/json-schema-org/JSON-Schema-Test-Suite
which is copyright Julian Berman, et. al, and released under the MIT license.
