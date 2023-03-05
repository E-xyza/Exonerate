defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(subschema, authority, pointer, opts) do
    {subfilters, contexts} =
      subschema
      |> Enum.map(&filters_for(&1, authority, pointer, opts))
      |> Enum.unzip()

    quote do
      defp unquote(Tools.call(authority, pointer, opts))({key, value}, path) do
        Enum.reduce_while(unquote(subfilters), :ok, fn
          {regex, fun}, :ok ->
            result =
              if Regex.match?(regex, key) do
                fun.(value, Path.join(path, key))
              else
                :ok
              end

            {:cont, result}

          _, error = {:error, _} ->
            {:halt, error}
        end)
      end

      unquote(contexts)
    end
  end

  defp filters_for({regex, _}, authority, pointer, opts) do
    pointer = JsonPointer.join(pointer, regex)
    fun = Tools.call(authority, pointer, opts)

    {quote do
       {sigil_r(<<unquote(regex)>>, []), &(unquote({fun, [], Elixir}) / 2)}
     end,
     quote do
       require Exonerate.Context

       Exonerate.Context.filter(
         unquote(authority),
         unquote(pointer),
         unquote(opts)
       )
     end}
  end
end
