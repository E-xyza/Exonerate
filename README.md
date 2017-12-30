# Exaggerate

**A JSONSchema -> Elixir module code generator**

Currently supports JSONSchema draft 0.4.  *except:*

- multipleOf is not supported for number types.  This is because
elixir does not support a floating point remainder guard, and also
because it is impossible for a floating point to guarantee sane results
(e.g. for IEEE Float64, `1.2 / 0.1 != 12`)

Works in progress:

- support for ref and remoteref
- code sanitization for degenerate forms, e.g. `{"properties":{}}`
- better error and warning handling during validation and code synthesis
- code cleanup for simpler dependency checking when the structure has only one dependency.
- code cleanup for degenerate arrays e.g. `[<contents>] |> Exonerate.error_reduction`
- code cleanup for degenerate functions e.g. `def <function>(val), do: :ok`
- make code generation available as a mix Task
- make code generation available as a macro

## Using the library

Add the following lines to your mix.exs

```elixir
  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:exonerate, git: "https://github.com/rstorsauce/exonerate.git", tag: "master"},
    ]
  end
```

## Installation

This library requires Elixir 1.6 (because of code prettification)

## Running unit tests

- basic mix-based unit and integration tests

```bash
  mix test
```

- comprehensive automated unit tests.  This will build a JSONSchema directory in
test/ that features automatically generated code and code testing.

```bash
  mix exoneratebuildtests
  mix test --only jsonschema
```

## response encoding.

the default response encoding for JSON is Poison.
