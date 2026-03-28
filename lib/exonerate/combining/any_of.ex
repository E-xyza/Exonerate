defmodule Exonerate.Combining.AnyOf do
  @moduledoc false

  alias Exonerate.Combining
  alias Exonerate.Degeneracy
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    subschemas = Tools.subschema(__CALLER__, resource, pointer)

    # Check degeneracy of each sub-schema
    degeneracies = Enum.map(subschemas, &Degeneracy.class/1)

    subschemas
    |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(degeneracies, resource, pointer, opts)
    |> Combining.dedupe(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  # special case, only one item
  defp build_filter({[any_of_call], [context]}, _degeneracies, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        unquote(any_of_call)(data, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, degeneracies, resource, pointer, opts) do
    function =
      case opts[:tracked] do
        :object ->
          build_tracked_object(calls, degeneracies, resource, pointer, opts)

        :array ->
          build_tracked_array(calls, degeneracies, resource, pointer, opts)

        nil ->
          build_untracked(calls, degeneracies, resource, pointer, opts)
      end

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  # For tracked modes, we must evaluate ALL branches to union/max results
  defp build_tracked_object(calls, degeneracies, resource, pointer, opts) do
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
    combine_expr = build_object_combine_expr(Enum.zip(result_vars, degeneracies), resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(combine_expr)
      end
    end
  end

  defp build_object_combine_expr(vars_with_degeneracies, resource, pointer) do
    # Start with error, fold over results
    # Track accumulator state: :error (initial), :ok, or :unknown
    initial = quote do: Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)
    initial_state = :error

    {expr, _final_state} =
      Enum.reduce(vars_with_degeneracies, {initial, initial_state}, fn {var, degeneracy}, {acc, acc_state} ->
        # Determine what cases to generate based on both accumulator state and var degeneracy
        {new_expr, new_state} = build_object_case(acc, var, degeneracy, acc_state, resource, pointer)
        {new_expr, new_state}
      end)

    expr
  end

  # Build a single case expression for object tracked mode
  # acc_state tracks whether the accumulator can be :ok, :error, or :unknown
  defp build_object_case(acc, var, var_degeneracy, acc_state, _resource, _pointer) do
    # Determine possible combinations
    acc_can_be_ok = acc_state in [:ok, :unknown]
    acc_can_be_error = acc_state in [:error, :unknown]
    var_can_be_ok = var_degeneracy in [:ok, :unknown]
    var_can_be_error = var_degeneracy in [:error, :unknown]

    # Build only the necessary clauses as {pattern, body} tuples
    clauses = []

    clauses = if acc_can_be_error and var_can_be_ok do
      pattern = quote do: {{:error, _opts}, {:ok, seen}}
      body = quote do: {:ok, seen}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_error and var_can_be_error do
      pattern = quote do: {{:error, opts}, {:error, error}}
      body = quote do: {:error, Keyword.update(opts, :errors, [error], &[error | &1])}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_ok and var_can_be_ok do
      pattern = quote do: {{:ok, seen}, {:ok, new_seen}}
      body = quote do: {:ok, MapSet.union(seen, new_seen)}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_ok and var_can_be_error do
      pattern = quote do: {{:ok, seen}, {:error, _}}
      body = quote do: {:ok, seen}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = Enum.reverse(clauses)

    case_expr = quote do: {unquote(acc), unquote(var)}
    expr = {:case, [], [case_expr, [do: clauses]]}

    # Calculate new state
    new_state = cond do
      # If var is always :ok, result is always :ok
      var_degeneracy == :ok -> :ok
      # If var is always :error, state stays the same
      var_degeneracy == :error -> acc_state
      # If acc is always :error and var is unknown, result is unknown
      acc_state == :error and var_degeneracy == :unknown -> :unknown
      # Otherwise unknown
      true -> :unknown
    end

    {expr, new_state}
  end

  defp build_tracked_array(calls, degeneracies, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    result_vars = Enum.with_index(calls, fn _, i -> Macro.var(:"result_#{i}", __MODULE__) end)

    assignments =
      Enum.zip(calls, result_vars)
      |> Enum.map(fn {subcall, var} ->
        quote do
          unquote(var) = unquote(subcall)(data, path)
        end
      end)

    combine_expr = build_array_combine_expr(Enum.zip(result_vars, degeneracies), resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote_splicing(assignments)
        unquote(combine_expr)
      end
    end
  end

  defp build_array_combine_expr(vars_with_degeneracies, resource, pointer) do
    # Same approach as object combine - track accumulator state
    initial = quote do: Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)
    initial_state = :error

    {expr, _final_state} =
      Enum.reduce(vars_with_degeneracies, {initial, initial_state}, fn {var, degeneracy}, {acc, acc_state} ->
        {new_expr, new_state} = build_array_case(acc, var, degeneracy, acc_state)
        {new_expr, new_state}
      end)

    expr
  end

  defp build_array_case(acc, var, var_degeneracy, acc_state) do
    acc_can_be_ok = acc_state in [:ok, :unknown]
    acc_can_be_error = acc_state in [:error, :unknown]
    var_can_be_ok = var_degeneracy in [:ok, :unknown]
    var_can_be_error = var_degeneracy in [:error, :unknown]

    clauses = []

    clauses = if acc_can_be_error and var_can_be_ok do
      pattern = quote do: {{:error, _opts}, {:ok, idx}}
      body = quote do: {:ok, idx}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_error and var_can_be_error do
      pattern = quote do: {{:error, opts}, {:error, error}}
      body = quote do: {:error, Keyword.update(opts, :errors, [error], &[error | &1])}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_ok and var_can_be_ok do
      pattern = quote do: {{:ok, idx}, {:ok, new_idx}}
      body = quote do: {:ok, max(idx, new_idx)}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = if acc_can_be_ok and var_can_be_error do
      pattern = quote do: {{:ok, idx}, {:error, _}}
      body = quote do: {:ok, idx}
      [{:->, [], [[pattern], body]} | clauses]
    else
      clauses
    end

    clauses = Enum.reverse(clauses)

    case_expr = quote do: {unquote(acc), unquote(var)}
    expr = {:case, [], [case_expr, [do: clauses]]}

    new_state = cond do
      var_degeneracy == :ok -> :ok
      var_degeneracy == :error -> acc_state
      acc_state == :error and var_degeneracy == :unknown -> :unknown
      true -> :unknown
    end

    {expr, new_state}
  end

  # For untracked mode, short-circuit on first success
  defp build_untracked(calls, degeneracies, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    calls_with_degeneracies = Enum.zip(calls, degeneracies)
    case_chain = build_untracked_case_chain(calls_with_degeneracies, resource, pointer)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools
        unquote(case_chain)
      end
    end
  end

  # Build nested case expressions that short-circuit on :ok
  # Handle degenerate schemas to avoid unreachable clause warnings

  defp build_untracked_case_chain([{last_call, degeneracy}], resource, pointer) do
    case degeneracy do
      :ok ->
        # Sub-schema always succeeds
        :ok

      :error ->
        # Sub-schema always fails
        quote do
          Exonerate.Tools.error_match(error) = unquote(last_call)(data, path)
          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path, errors: [error])
        end

      :unknown ->
        quote do
          case unquote(last_call)(data, path) do
            :ok ->
              :ok

            Exonerate.Tools.error_match(error) ->
              Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path, errors: [error])
          end
        end
    end
  end

  defp build_untracked_case_chain([{first_call, degeneracy} | rest], resource, pointer) do
    case degeneracy do
      :ok ->
        # Sub-schema always succeeds, no need to check rest
        :ok

      :error ->
        # Sub-schema always fails, collect error and continue to rest
        error_0 = Macro.var(:error_0, __MODULE__)
        rest_chain = build_untracked_case_chain_inner(rest, resource, pointer, [error_0])

        quote do
          Exonerate.Tools.error_match(unquote(error_0)) = unquote(first_call)(data, path)
          unquote(rest_chain)
        end

      :unknown ->
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
  end

  defp build_untracked_case_chain_inner([{last_call, degeneracy}], resource, pointer, error_vars) do
    case degeneracy do
      :ok ->
        # Sub-schema always succeeds
        :ok

      :error ->
        # Sub-schema always fails
        error_last = Macro.var(:error_last, __MODULE__)
        all_errors = Enum.reverse([error_last | error_vars])
        errors_list = build_errors_list(all_errors)

        quote do
          Exonerate.Tools.error_match(error_last) = unquote(last_call)(data, path)
          Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
            errors: unquote(errors_list)
          )
        end

      :unknown ->
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
  end

  defp build_untracked_case_chain_inner([{next_call, degeneracy} | rest], resource, pointer, error_vars) do
    case degeneracy do
      :ok ->
        # Sub-schema always succeeds
        :ok

      :error ->
        # Sub-schema always fails, collect error and continue
        error_var = Macro.var(:"error_#{length(error_vars) + 1}", __MODULE__)
        rest_chain = build_untracked_case_chain_inner(rest, resource, pointer, [error_var | error_vars])

        quote do
          Exonerate.Tools.error_match(unquote(error_var)) = unquote(next_call)(data, path)
          unquote(rest_chain)
        end

      :unknown ->
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
