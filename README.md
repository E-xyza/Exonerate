# Exonerate

**A JSONSchema -> Elixir module code generator**

Currently supports JSONSchema draft 0.7.  *except:*

- multipleOf is not supported for number types.  This is because
elixir does not support a floating point remainder guard, and also
because it is impossible for a floating point to guarantee sane results
(e.g. for IEEE Float64, `1.2 / 0.1 != 12`)
- currently remoteref is not supported.

Works in progress:

- more user-friendly usage surface
- support for remoteref
- code sanitization for degenerate forms, e.g. `{"properties":{}}`
- code cleanup for simpler dependency checking when the structure has only one dependency.
- code cleanup for degenerate arrays e.g. `[<contents>] |> Exonerate.error_reduction`

## Installation

Add the following lines to your mix.exs

```elixir
  defp deps do
    [
      # -- your favorite dependencies here
      {:exonerate, git: "https://github.com/rstorsauce/exonerate.git", tag: "master"},
    ]
  end
```

## Quick Start

```elixir

defmodule SchemaModule do
  import Exonerate

  @schemadoc """
  validates our input
  """
  defschema validate_input: """
  {
    "type":"object",
    "properties":{
      "parameter":{"type":"integer"}
    }
  }
  """
end
```
```
iex> SchemaModule.validate_input("some string")
{:mismatch, {"#", "some string"}}

iex> SchemaModule.validate_input(%{"parameter" => "2"})
{:mismatch, {"#/properties/parameter", "2"}}

iex> SchemaModule.validate_input(%{"parameter" => 2})
:ok

iex> h SchemaModule.validate_input                   

                            def validate_input(val)                             

  @spec validate_input(Exonerate.json()) :: :ok | Exonerate.mismatch()

validates our input

Matches JSONSchema:

    {
      "type":"object",
      "properties":{
        "parameter":{"type":"integer"}
      }
    }
    
```


## Running unit tests

- basic mix-based unit and integration tests

```bash
  mix test
```

- comprehensive automated unit tests.  This will build a JSONSchema directory in
test/automated that features automatically generated code and code testing.

```bash
  mix exonerate.build_tests
  mix test
```

## response encoding.

the default response encoding for JSON is Jason.
