defmodule Exonerate.Filter.Contains do
  @moduledoc false

  # NOTE this generates an iterator function

  alias Exonerate.Context
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because this filter
    # is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_find_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  # if there's a minContains filter, don't create the find filter
  defp build_find_filter(%{"minContains" => _}, _, _, _), do: []

  defp build_find_filter(context = %{"contains" => _}, resource, pointer, opts) do
    call = Iterator.call(resource, pointer, opts)

    terminal_params =
      Iterator.select(
        context,
        quote do
          [array, [], path, _index, contains_count, _first_unseen_index, _unique_items]
        end
      )

    contains_pointer = JsonPointer.join(pointer, "contains")

    quote do
      defp unquote(call)(unquote_splicing(terminal_params)) when contains_count === 0 do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(contains_pointer), path)
      end
    end
  end

  defp build_find_filter(_, _, _, _), do: []

  defmacro context(resource, pointer, opts) do
    opts = Context.scrub_opts(opts)

    resource
    |> build_context(pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_context(resource, pointer, opts) do
    quote do
      require Exonerate.Context

      Exonerate.Context.filter(
        unquote(resource),
        unquote(pointer),
        unquote(Context.scrub_opts(opts))
      )
    end
  end

  defmacro next_contains(resource, pointer, ast, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_next_contains(ast, resource, pointer, opts)
  end

  defp build_next_contains(
         %{"contains" => _, "maxContains" => _},
         ast,
         resource,
         pointer,
         opts
       ) do
    [contains_count_ast, item_ast, path_ast] = ast
    contains_call = Tools.call(resource, JsonPointer.join(pointer, "contains"), opts)

    quote do
      unquote(contains_count_ast) =
        case unquote(contains_call)(unquote(item_ast), unquote(path_ast)) do
          :ok ->
            unquote(contains_count_ast) + 1

          {:error, _} ->
            unquote(contains_count_ast)
        end
    end
  end

  defp build_next_contains(context = %{"contains" => _}, ast, resource, pointer, opts) do
    [contains_count_ast, item_ast, path_ast] = ast
    needed = Map.get(context, "minContains", 1)
    contains_call = Tools.call(resource, JsonPointer.join(pointer, "contains"), opts)

    quote do
      unquote(contains_count_ast) =
        cond do
          unquote(contains_count_ast) >= unquote(needed) ->
            unquote(contains_count_ast)

          :ok === unquote(contains_call)(unquote(item_ast), unquote(path_ast)) ->
            unquote(contains_count_ast) + 1

          true ->
            unquote(contains_count_ast)
        end
    end
  end

  defp build_next_contains(_, _, _, _, _), do: []
end
