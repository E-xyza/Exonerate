defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false
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

    init =
      if opts[:tracked] do
        {:ok, false}
      else
        :ok
      end

    capture =
      if opts[:tracked] do
        quote do
          {:ok, visited}
        end
      else
        :ok
      end

    evaluation =
      if opts[:tracked] do
        quote do
          case fun.(value, Path.join(path, key)) do
            :ok -> {:ok, true}
            error -> error
          end
        end
      else
        quote do
          fun.(value, Path.join(path, key))
        end
      end

    negative =
      if opts[:tracked] do
        quote do
          {:ok, visited}
        end
      else
        :ok
      end

    quote do
      defp unquote(Tools.call(authority, pointer, opts))({key, value}, path) do
        Enum.reduce_while(unquote(subfilters), unquote(init), fn
          {regex, fun}, unquote(capture) ->
            result =
              if Regex.match?(regex, key) do
                unquote(evaluation)
              else
                unquote(negative)
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
    opts = Keyword.delete(opts, :tracked)
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
