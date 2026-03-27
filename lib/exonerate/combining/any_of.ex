defmodule Exonerate.Combining.AnyOf do
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

  # special case, only one item
  defp build_filter({[any_of_call], [context]}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        unquote(any_of_call)(data, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, resource, pointer, opts) do
    function =
      case opts[:tracked] do
        :object ->
          build_tracked_object(calls, resource, pointer, opts)

        :array ->
          build_tracked_array(calls, resource, pointer, opts)

        nil ->
          build_untracked(calls, resource, pointer, opts)
      end

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  # For tracked modes, we must evaluate ALL branches to union/max results
  defp build_tracked_object(calls, resource, pointer, opts) do
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

    # Generate the fold expression to combine results
    combine_expr = build_object_combine_expr(result_vars, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(combine_expr)
      end
    end
  end

  defp build_object_combine_expr(result_vars, resource, pointer) do
    # Start with error, fold over results
    initial = quote do: Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)

    Enum.reduce(result_vars, initial, fn var, acc ->
      quote do
        case {unquote(acc), unquote(var)} do
          {{:error, opts}, {:ok, seen}} ->
            {:ok, seen}

          {{:error, opts}, {:error, error}} ->
            {:error, Keyword.update(opts, :errors, [error], &[error | &1])}

          {{:ok, seen}, {:ok, new_seen}} ->
            {:ok, MapSet.union(seen, new_seen)}

          {{:ok, seen}, {:error, _}} ->
            {:ok, seen}
        end
      end
    end)
  end

  defp build_tracked_array(calls, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    result_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"result_#{i}", __MODULE__) end)

    assignments =
      Enum.zip(calls, result_vars)
      |> Enum.map(fn {subcall, var} ->
        quote do
          unquote(var) = unquote(subcall)(data, path)
        end
      end)

    combine_expr = build_array_combine_expr(result_vars, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(combine_expr)
      end
    end
  end

  defp build_array_combine_expr(result_vars, resource, pointer) do
    initial = quote do: Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)

    Enum.reduce(result_vars, initial, fn var, acc ->
      quote do
        case {unquote(acc), unquote(var)} do
          {{:error, opts}, {:ok, idx}} ->
            {:ok, idx}

          {{:error, opts}, {:error, error}} ->
            {:error, Keyword.update(opts, :errors, [error], &[error | &1])}

          {{:ok, idx}, {:ok, new_idx}} ->
            {:ok, max(idx, new_idx)}

          {{:ok, idx}, {:error, _}} ->
            {:ok, idx}
        end
      end
    end)
  end

  # For untracked mode, short-circuit on first success
  defp build_untracked(calls, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    case_chain = build_untracked_case_chain(calls, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote(case_chain)
      end
    end
  end

  # Build nested case expressions that short-circuit on :ok
  defp build_untracked_case_chain([last_call], resource, pointer) do
    quote do
      case unquote(last_call)(data, path) do
        :ok ->
          :ok

        Exonerate.Tools.error_match(error) ->
          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path, errors: [error])
      end
    end
  end

  defp build_untracked_case_chain([first_call | rest], resource, pointer) do
    error_0 = Macro.var(:error_0, __MODULE__)
    rest_chain = build_untracked_case_chain_inner(rest, resource, pointer, [error_0])

    quote do
      case unquote(first_call)(data, path) do
        :ok ->
          :ok

        Exonerate.Tools.error_match(unquote(error_0)) ->
          unquote(rest_chain)
      end
    end
  end

  defp build_untracked_case_chain_inner([last_call], resource, pointer, error_vars) do
    all_errors = Enum.reverse([Macro.var(:error_last, __MODULE__) | error_vars])
    errors_list = build_errors_list(all_errors)

    quote do
      case unquote(last_call)(data, path) do
        :ok ->
          :ok

        Exonerate.Tools.error_match(error_last) ->
          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            errors: unquote(errors_list)
          )
      end
    end
  end

  defp build_untracked_case_chain_inner([next_call | rest], resource, pointer, error_vars) do
    error_var = Macro.var(:"error_#{length(error_vars) + 1}", __MODULE__)
    rest_chain = build_untracked_case_chain_inner(rest, resource, pointer, [error_var | error_vars])

    quote do
      case unquote(next_call)(data, path) do
        :ok ->
          :ok

        Exonerate.Tools.error_match(unquote(error_var)) ->
          unquote(rest_chain)
      end
    end
  end

  defp build_errors_list(vars) do
    Enum.reduce(Enum.reverse(vars), [], fn var, acc ->
      quote do: [unquote(var) | unquote(acc)]
    end)
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
