defmodule Exonerate.Combining.AllOf do
  @moduledoc false
  alias Exonerate.Combining
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Combining.dedupe(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter({[all_of_call], [context]}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        unquote(all_of_call)(data, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    case opts[:tracked] do
      :object ->
        build_tracked_object(call, calls, contexts)

      :array ->
        build_tracked_array(call, calls, contexts)

      nil ->
        build_untracked(call, calls, contexts)
    end
  end

  # Build a with-chain for tracked object mode
  # Each call returns {:ok, seen_set}, we union them all
  defp build_tracked_object(call, calls, contexts) do
    seen_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"seen_#{i}", __MODULE__) end)

    with_clauses =
      Enum.zip(calls, seen_vars)
      |> Enum.map(fn {subcall, seen_var} ->
        quote do
          {:ok, unquote(seen_var)} <- unquote(subcall)(data, path)
        end
      end)

    union_expr = build_union_expr(seen_vars)

    quote do
      defp unquote(call)(data, path) do
        with unquote_splicing(with_clauses) do
          {:ok, unquote(union_expr)}
        end
      end

      unquote(contexts)
    end
  end

  defp build_union_expr([single]), do: single
  defp build_union_expr([first | rest]) do
    Enum.reduce(rest, first, fn var, acc ->
      quote do: MapSet.union(unquote(acc), unquote(var))
    end)
  end

  # Build a with-chain for tracked array mode
  # Each call returns {:ok, index}, we take the max
  defp build_tracked_array(call, calls, contexts) do
    index_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"idx_#{i}", __MODULE__) end)

    with_clauses =
      Enum.zip(calls, index_vars)
      |> Enum.map(fn {subcall, idx_var} ->
        quote do
          {:ok, unquote(idx_var)} <- unquote(subcall)(data, path)
        end
      end)

    max_expr = build_max_expr(index_vars)

    quote do
      defp unquote(call)(data, path) do
        with unquote_splicing(with_clauses) do
          {:ok, unquote(max_expr)}
        end
      end

      unquote(contexts)
    end
  end

  defp build_max_expr([single]), do: single
  defp build_max_expr([first | rest]) do
    Enum.reduce(rest, first, fn var, acc ->
      quote do: max(unquote(acc), unquote(var))
    end)
  end

  # Build a with-chain for untracked mode
  # Each call returns :ok, we just need all to succeed
  defp build_untracked(call, calls, contexts) do
    with_clauses =
      Enum.map(calls, fn subcall ->
        quote do
          :ok <- unquote(subcall)(data, path)
        end
      end)

    quote do
      defp unquote(call)(data, path) do
        with unquote_splicing(with_clauses) do
          :ok
        end
      end

      unquote(contexts)
    end
  end

  defp call_and_context(_, index, resource, pointer, opts) do
    pointer = JsonPtr.join(pointer, "#{index}")
    call = Tools.call(resource, pointer, opts)

    context =
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end

    {call, context}
  end
end
