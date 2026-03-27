defmodule Exonerate.Combining.OneOf do
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
    function =
      case opts[:tracked] do
        :object ->
          build_tracked(calls, resource, pointer, opts)

        :array ->
          build_tracked(calls, resource, pointer, opts)

        nil ->
          build_untracked(calls, resource, pointer, opts)
      end

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  # For tracked modes, we must evaluate ALL branches to ensure exactly one matches
  defp build_tracked(calls, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    result_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"result_#{i}", __MODULE__) end)

    # Generate: result_0 = call_0(data, path)
    assignments =
      Enum.zip(calls, result_vars)
      |> Enum.map(fn {subcall, var} ->
        quote do
          unquote(var) = unquote(subcall)(data, path)
        end
      end)

    check_expr = build_tracked_check_expr(result_vars, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(check_expr)
      end
    end
  end

  defp build_tracked_check_expr(result_vars, resource, pointer) do
    # Build a list of {result_var, index} tuples
    indexed_vars = Enum.with_index(result_vars)

    quote do
      # Collect all results with their indices
      results = unquote(build_results_list(indexed_vars))

      # Separate successes and failures
      {successes, failures} =
        Enum.split_with(results, fn {result, _idx} ->
          match?({:ok, _}, result)
        end)

      case successes do
        [{ok = {:ok, _seen}, _idx}] ->
          # Exactly one match - success
          ok

        [] ->
          # No matches - collect all errors
          errors = Enum.map(failures, fn {{:error, _} = err, _idx} -> err end)

          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            reason: "no matches",
            errors: errors
          )

        multiple ->
          # Multiple matches
          matches =
            Enum.map(multiple, fn {_, idx} ->
              "/" <> Path.join(unquote(pointer) ++ ["#{idx}"])
            end)

          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            matches: matches,
            reason: "multiple matches"
          )
      end
    end
  end

  defp build_results_list(indexed_vars) do
    elements =
      Enum.map(indexed_vars, fn {var, idx} ->
        quote do: {unquote(var), unquote(idx)}
      end)

    quote do: unquote(elements)
  end

  # For untracked mode, we also must evaluate ALL branches to ensure exactly one matches
  defp build_untracked(calls, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    result_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"result_#{i}", __MODULE__) end)

    # Generate: result_0 = call_0(data, path)
    assignments =
      Enum.zip(calls, result_vars)
      |> Enum.map(fn {subcall, var} ->
        quote do
          unquote(var) = unquote(subcall)(data, path)
        end
      end)

    check_expr = build_untracked_check_expr(result_vars, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(check_expr)
      end
    end
  end

  defp build_untracked_check_expr(result_vars, resource, pointer) do
    indexed_vars = Enum.with_index(result_vars)

    quote do
      results = unquote(build_results_list(indexed_vars))

      {successes, failures} =
        Enum.split_with(results, fn {result, _idx} ->
          result == :ok
        end)

      case successes do
        [{:ok, _idx}] ->
          # Exactly one match - success
          :ok

        [] ->
          # No matches - collect all errors
          errors = Enum.map(failures, fn {err, _idx} -> err end)

          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            reason: "no matches",
            errors: errors
          )

        multiple ->
          # Multiple matches
          matches =
            Enum.map(multiple, fn {_, idx} ->
              "/" <> Path.join(unquote(pointer) ++ ["#{idx}"])
            end)

          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            matches: matches,
            reason: "multiple matches"
          )
      end
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
