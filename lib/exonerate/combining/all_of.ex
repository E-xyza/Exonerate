defmodule Exonerate.Combining.AllOf do
  @moduledoc false
  alias Exonerate.Combining
  alias Exonerate.Context
  alias Exonerate.PropertyRegistry
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    caller = __CALLER__
    subschemas = Tools.subschema(caller, resource, pointer)

    # Check if we can optimize with single-pass property iteration
    {optimizable, non_optimizable} = PropertyRegistry.analyze_subschemas(caller, resource, pointer)

    if length(optimizable) >= 2 and opts[:tracked] != :array do
      # Use optimized single-pass iteration for property-only sub-schemas
      build_optimized_filter(caller, resource, pointer, subschemas, optimizable, non_optimizable, opts)
    else
      # Use standard filter generation
      subschemas
      |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
      |> Enum.unzip()
      |> build_filter(resource, pointer, opts)
    end
    |> Combining.dedupe(caller, resource, pointer, opts)
    |> Tools.maybe_dump(caller, opts)
  end

  # Build an optimized filter that merges property-only sub-schemas into a single pass
  defp build_optimized_filter(caller, resource, pointer, subschemas, optimizable, non_optimizable, opts) do
    call = Tools.call(resource, pointer, opts)

    # Build registry for optimizable sub-schemas
    registry = PropertyRegistry.build_registry(caller, resource, pointer, optimizable)

    # Generate calls for non-optimizable sub-schemas (standard processing)
    {non_opt_calls, non_opt_contexts} =
      non_optimizable
      |> Enum.map(fn index ->
        {Enum.at(subschemas, index), index}
      end)
      |> Enum.map(fn {_schema, index} ->
        call_and_context(nil, index, resource, pointer, opts)
      end)
      |> Enum.unzip()

    # Generate the merged iterator call
    merged_iterator_pointer = JsonPtr.join(pointer, ":merged_iterator")
    merged_iterator_call = Tools.call(resource, merged_iterator_pointer, opts)

    # Generate property validators and merged iterator
    property_validators = generate_property_validators(resource, pointer, registry, opts)
    merged_iterator = generate_merged_iterator(resource, pointer, registry, opts)

    case opts[:tracked] do
      :object ->
        build_optimized_tracked_object(
          call,
          merged_iterator_call,
          non_opt_calls,
          property_validators,
          merged_iterator,
          non_opt_contexts
        )

      nil ->
        build_optimized_untracked(
          call,
          merged_iterator_call,
          non_opt_calls,
          property_validators,
          merged_iterator,
          non_opt_contexts
        )

      :array ->
        # Array tracking doesn't benefit from property optimization
        # Fall back to standard processing (this shouldn't be reached due to guard above)
        subschemas
        |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
        |> Enum.unzip()
        |> build_filter(resource, pointer, opts)
    end
  end

  defp generate_property_validators(resource, pointer, registry, opts) do
    scrubbed_opts = Context.scrub_opts(opts)

    property_validators =
      for {prop_name, validators} <- registry.properties do
        merged_pointer = JsonPtr.join(pointer, [":merged_props", prop_name])
        merged_call = Tools.call(resource, merged_pointer, opts)

        validator_calls =
          Enum.map(validators, fn {_index, prop_pointer, _schema} ->
            call = Tools.call(resource, prop_pointer, scrubbed_opts)
            quote do: unquote(call)(value, prop_path)
          end)

        with_clauses =
          Enum.map(validator_calls, fn call_expr ->
            quote do: :ok <- unquote(call_expr)
          end)

        accessor_contexts =
          Enum.map(validators, fn {_index, prop_pointer, _schema} ->
            quote do
              require Exonerate.Context
              Exonerate.Context.filter(unquote(resource), unquote(prop_pointer), unquote(scrubbed_opts))
            end
          end)

        if opts[:tracked] do
          quote do
            defp unquote(merged_call)({unquote(prop_name), value}, path) do
              prop_path = Path.join(path, unquote(prop_name))

              with unquote_splicing(with_clauses) do
                {:ok, true}
              end
            end

            unquote(accessor_contexts)
          end
        else
          quote do
            defp unquote(merged_call)({unquote(prop_name), value}, path) do
              prop_path = Path.join(path, unquote(prop_name))

              with unquote_splicing(with_clauses) do
                :ok
              end
            end

            unquote(accessor_contexts)
          end
        end
      end

    # Generate pattern property accessors
    pattern_accessors =
      for {_pattern, _index, pattern_pointer, _schema} <- registry.pattern_properties do
        quote do
          require Exonerate.Context
          Exonerate.Context.filter(unquote(resource), unquote(pattern_pointer), unquote(scrubbed_opts))
        end
      end

    quote do
      unquote(property_validators)
      unquote(pattern_accessors)
    end
  end

  defp generate_merged_iterator(resource, pointer, registry, opts) do
    iterator_pointer = JsonPtr.join(pointer, ":merged_iterator")
    iterator_call = Tools.call(resource, iterator_pointer, opts)
    scrubbed_opts = Context.scrub_opts(opts)

    # Generate property dispatch clauses
    prop_names = Map.keys(registry.properties)

    property_clauses =
      for prop_name <- prop_names do
        merged_pointer = JsonPtr.join(pointer, [":merged_props", prop_name])
        merged_call = Tools.call(resource, merged_pointer, opts)

        # Build case clause AST: pattern -> body
        pattern = quote do: {unquote(prop_name), value}
        body = quote do: unquote(merged_call)({unquote(prop_name), value}, path)

        {:->, [], [[pattern], body]}
      end

    # Generate pattern property checks
    pattern_checks =
      for {pattern, _index, pattern_pointer, _schema} <- registry.pattern_properties do
        pattern_call = Tools.call(resource, pattern_pointer, scrubbed_opts)

        if opts[:tracked] do
          quote do
            if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
              case unquote(pattern_call)(value, Path.join(path, key)) do
                :ok -> {:ok, true}
                error -> error
              end
            else
              {:ok, visited}
            end
          end
        else
          quote do
            if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
              unquote(pattern_call)(value, Path.join(path, key))
            else
              :ok
            end
          end
        end
      end

    # Build combined pattern check
    combined_pattern_check =
      case pattern_checks do
        [] ->
          if opts[:tracked], do: quote(do: {:ok, false}), else: :ok

        [single] ->
          single

        multiple ->
          if opts[:tracked] do
            Enum.reduce(Enum.reverse(multiple), quote(do: {:ok, visited}), fn check, acc ->
              quote do
                case unquote(check) do
                  {:ok, new_visited} ->
                    visited = visited or new_visited
                    unquote(acc)

                  error ->
                    error
                end
              end
            end)
          else
            with_clauses = Enum.map(multiple, fn check -> quote do: :ok <- unquote(check) end)

            quote do
              with unquote_splicing(with_clauses) do
                :ok
              end
            end
          end
      end

    # Default clause for unknown properties
    default_clause =
      if opts[:tracked] do
        pattern = quote do: {_key, _value}
        body = quote do: {:ok, false}
        {:->, [], [[pattern], body]}
      else
        pattern = quote do: {_key, _value}
        body = :ok
        {:->, [], [[pattern], body]}
      end

    # Build the iterator
    # Combine property clauses with default clause
    all_clauses = property_clauses ++ [default_clause]

    # Build the case expression programmatically
    case_expr = quote do: {key, value}
    case_block = {:case, [], [case_expr, [do: all_clauses]]}

    if opts[:tracked] do
      quote do
        defp unquote(iterator_call)(object, path) do
          require Exonerate.Tools

          Enum.reduce_while(object, {:ok, MapSet.new()}, fn
            {key, value}, {:ok, seen} ->
              visited = false

              result = unquote(case_block)

              case result do
                {:ok, prop_visited} ->
                  case unquote(combined_pattern_check) do
                    {:ok, pattern_visited} ->
                      new_seen =
                        if prop_visited or pattern_visited do
                          MapSet.put(seen, key)
                        else
                          seen
                        end

                      {:cont, {:ok, new_seen}}

                    Exonerate.Tools.error_match(error) ->
                      {:halt, error}
                  end

                Exonerate.Tools.error_match(error) ->
                  {:halt, error}
              end

            _, Exonerate.Tools.error_match(error) ->
              {:halt, error}
          end)
        end
      end
    else
      quote do
        defp unquote(iterator_call)(object, path) do
          require Exonerate.Tools

          Enum.reduce_while(object, :ok, fn
            {key, value}, :ok ->
              result = unquote(case_block)

              case result do
                :ok ->
                  {:cont, unquote(combined_pattern_check)}

                Exonerate.Tools.error_match(error) ->
                  {:halt, error}
              end
          end)
        end
      end
    end
  end

  defp build_optimized_tracked_object(call, merged_iterator_call, non_opt_calls, property_validators, merged_iterator, non_opt_contexts) do
    # Build with-chain that includes merged iterator and non-optimizable calls
    all_calls = [merged_iterator_call | non_opt_calls]
    seen_vars = Enum.with_index(all_calls, fn _, i -> Macro.var(:"seen_#{i}", __MODULE__) end)

    with_clauses =
      Enum.zip(all_calls, seen_vars)
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

      unquote(property_validators)
      unquote(merged_iterator)
      unquote(non_opt_contexts)
    end
  end

  defp build_optimized_untracked(call, merged_iterator_call, non_opt_calls, property_validators, merged_iterator, non_opt_contexts) do
    # Build with-chain that includes merged iterator and non-optimizable calls
    all_calls = [merged_iterator_call | non_opt_calls]

    with_clauses =
      Enum.map(all_calls, fn subcall ->
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

      unquote(property_validators)
      unquote(merged_iterator)
      unquote(non_opt_contexts)
    end
  end

  # Standard filter building (unchanged)
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
