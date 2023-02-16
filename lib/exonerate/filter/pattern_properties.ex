defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(pointer)
    |> Enum.map(fn
      {pattern, _} ->
        pointer = JsonPointer.traverse(pointer, pattern)

        quote do
          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
        end
    end)
    |> wrap_entry_and_selector(name, pointer)
    |> Tools.maybe_dump(opts)
  end

  defp wrap_entry_and_selector(code, name, pointer) do
    schema =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    starters =
      Enum.map(schema, fn {regex, _} ->
        {String.to_atom(regex),
         quote do
           sigil_r(<<unquote(regex)>>, [])
         end}
      end)

    selector =
      pointer
      |> JsonPointer.traverse(":selector")
      |> Tools.pointer_to_fun_name(authority: name)

    entrypoint =
      pointer
      |> JsonPointer.traverse(":entrypoint")
      |> Tools.pointer_to_fun_name(authority: name)

    calls = Enum.map(schema, &kv_to_entrypoint(&1, entrypoint, name, pointer))

    # selector returns nil or a list of things that it matches
    quote do
      defp unquote(selector)(key, regexes \\ unquote(starters), so_far \\ [])
      defp unquote(selector)(key, [], []), do: nil
      defp unquote(selector)(key, [], so_far), do: so_far

      defp unquote(selector)(key, [{atom, regex} | rest], so_far) do
        if Regex.match?(regex, key) do
          unquote(selector)(key, rest, [atom | so_far])
        else
          unquote(selector)(key, rest, so_far)
        end
      end

      defp unquote(entrypoint)(content, path, []), do: :ok
      unquote(calls)

      unquote(code)
    end
  end

  defp kv_to_entrypoint({regex, _}, entrypoint, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(regex)
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      defp unquote(entrypoint)(content, path, [regex | rest]) do
        case unquote(call)(content, path) do
          :ok -> unquote(entrypoint)(content, path, rest)
          error -> error
        end
      end
    end
  end
end
