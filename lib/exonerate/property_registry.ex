defmodule Exonerate.PropertyRegistry do
  @moduledoc """
  Compile-time registry for consolidating property validators across combining schemas.

  When combining filters (allOf, anyOf, oneOf) contain sub-schemas with properties,
  this module collects all property validators and allows generating a single-pass
  iteration instead of iterating once per sub-schema.

  ## Architecture

  The registry collects property definitions from multiple sub-schemas and generates
  a merged iterator that validates all properties in a single pass.

  ## Combining Semantics

  - **allOf**: All validators for a property must pass (AND semantics)
  - **anyOf**: At least one sub-schema's validators must pass
  - **oneOf**: Exactly one sub-schema's validators must pass
  """

  alias Exonerate.Context
  alias Exonerate.Tools

  # Keys that are allowed in a property-only schema (can be merged)
  @mergeable_keys MapSet.new([
    "type",
    "properties",
    "patternProperties",
    # Metadata keys that don't affect validation
    "title",
    "description",
    "examples",
    "default",
    "$comment"
  ])

  @doc """
  Checks if a sub-schema is "property-only" and can be merged.

  A schema is property-only if it only contains:
  - type (must include "object" or be absent)
  - properties
  - patternProperties
  - metadata (title, description, etc.)

  Returns true if the schema can be fully handled by the merged property iterator.
  """
  def is_property_only_schema?(caller, resource, pointer) do
    schema = Tools.subschema(caller, resource, pointer)
    is_property_only_schema_impl?(schema)
  end

  defp is_property_only_schema_impl?(schema) when is_boolean(schema), do: false

  defp is_property_only_schema_impl?(schema) when is_map(schema) do
    # Must have at least properties or patternProperties
    has_properties? = is_map_key(schema, "properties") or is_map_key(schema, "patternProperties")

    unless has_properties? do
      false
    else
      # Check that all keys are mergeable
      schema_keys = schema |> Map.keys() |> MapSet.new()
      extra_keys = MapSet.difference(schema_keys, @mergeable_keys)

      if MapSet.size(extra_keys) > 0 do
        false
      else
        # If type is present, it must include "object"
        case schema["type"] do
          nil -> true
          "object" -> true
          types when is_list(types) -> "object" in types
          _ -> false
        end
      end
    end
  end

  @doc """
  Analyzes sub-schemas in a combining filter and returns optimization info.

  Returns a tuple:
    {optimizable_indices, non_optimizable_indices}

  Where:
    - optimizable_indices: list of sub-schema indices that can be merged
    - non_optimizable_indices: list of indices that need standard processing
  """
  def analyze_subschemas(caller, resource, pointer) do
    subschemas = Tools.subschema(caller, resource, pointer)

    subschemas
    |> Enum.with_index()
    |> Enum.split_with(fn {_schema, index} ->
      sub_pointer = JsonPtr.join(pointer, "#{index}")
      is_property_only_schema?(caller, resource, sub_pointer)
    end)
    |> then(fn {optimizable, non_optimizable} ->
      {Enum.map(optimizable, fn {_, i} -> i end), Enum.map(non_optimizable, fn {_, i} -> i end)}
    end)
  end

  @doc """
  Checks if optimization is beneficial for the given combining filter.

  Returns true if there are at least 2 optimizable sub-schemas (worth the overhead).
  """
  def can_optimize?(caller, resource, pointer) do
    {optimizable, _non_optimizable} = analyze_subschemas(caller, resource, pointer)
    length(optimizable) >= 2
  end

  @doc """
  Builds a merged property registry from optimizable sub-schema indices.

  Returns:
    %{
      properties: %{property_name => [{sub_index, pointer, schema}]},
      pattern_properties: [{pattern, sub_index, pointer, schema}]
    }
  """
  def build_registry(caller, resource, pointer, indices) do
    {props, patterns} =
      indices
      |> Enum.map(fn index ->
        sub_pointer = JsonPtr.join(pointer, "#{index}")
        schema = Tools.subschema(caller, resource, sub_pointer)

        # Extract properties
        props =
          case schema["properties"] do
            nil ->
              []

            prop_map ->
              for {key, prop_schema} <- prop_map do
                prop_pointer = JsonPtr.join(sub_pointer, ["properties", key])
                {key, {index, prop_pointer, prop_schema}}
              end
          end

        # Extract patternProperties
        patterns =
          case schema["patternProperties"] do
            nil ->
              []

            pattern_map ->
              for {pattern, pattern_schema} <- pattern_map do
                pattern_pointer = JsonPtr.join(sub_pointer, ["patternProperties", pattern])
                {pattern, index, pattern_pointer, pattern_schema}
              end
          end

        {props, patterns}
      end)
      |> Enum.unzip()

    # Group properties by name
    merged_props =
      props
      |> List.flatten()
      |> Enum.group_by(fn {key, _} -> key end, fn {_, entry} -> entry end)

    %{
      properties: merged_props,
      pattern_properties: List.flatten(patterns)
    }
  end

  @doc """
  Generates a merged property validator function for allOf semantics.

  This creates a function that validates a property against ALL validators
  from all merged sub-schemas that define that property.
  """
  defmacro generate_allof_property_validators(resource, pointer, registry, opts) do
    registry = Macro.expand_literals(registry, __CALLER__)

    property_validators =
      for {prop_name, validators} <- registry.properties do
        generate_single_property_validator(__CALLER__, resource, pointer, prop_name, validators, opts)
      end

    pattern_validators =
      for {pattern, _index, pattern_pointer, _schema} <- registry.pattern_properties do
        generate_single_pattern_accessor(__CALLER__, resource, pattern, pattern_pointer, opts)
      end

    quote do
      unquote(property_validators)
      unquote(pattern_validators)
    end
  end

  # Generates a validator for a single property that chains all sub-schema validators
  defp generate_single_property_validator(_caller, resource, pointer, prop_name, validators, opts) do
    # Generate the merged call name
    merged_pointer = JsonPtr.join(pointer, [":merged_props", prop_name])
    merged_call = Tools.call(resource, merged_pointer, opts)

    # Generate the chain of validator calls
    scrubbed_opts = Context.scrub_opts(opts)

    validator_calls =
      Enum.map(validators, fn {_index, prop_pointer, _schema} ->
        call = Tools.call(resource, prop_pointer, scrubbed_opts)
        quote do: unquote(call)(value, prop_path)
      end)

    # Chain with `with` for short-circuit on error
    with_clauses =
      Enum.map(validator_calls, fn call ->
        quote do: :ok <- unquote(call)
      end)

    # Generate accessor contexts (the actual sub-schema validators)
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

  # Generates accessor context for a pattern property
  defp generate_single_pattern_accessor(_caller, resource, _pattern, pattern_pointer, opts) do
    scrubbed_opts = Context.scrub_opts(opts)

    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pattern_pointer), unquote(scrubbed_opts))
    end
  end

  @doc """
  Generates a merged iterator that validates all properties in a single pass.
  """
  defmacro generate_allof_merged_iterator(resource, pointer, registry, opts) do
    registry = Macro.expand_literals(registry, __CALLER__)
    build_merged_iterator(__CALLER__, resource, pointer, registry, opts)
  end

  defp build_merged_iterator(_caller, resource, pointer, registry, opts) do
    iterator_pointer = JsonPtr.join(pointer, ":merged_iterator")
    iterator_call = Tools.call(resource, iterator_pointer, opts)

    # Generate property dispatch calls
    prop_names = Map.keys(registry.properties)

    property_clauses =
      for prop_name <- prop_names do
        merged_pointer = JsonPtr.join(pointer, [":merged_props", prop_name])
        merged_call = Tools.call(resource, merged_pointer, opts)

        if opts[:tracked] do
          quote do
            {unquote(prop_name), value} ->
              unquote(merged_call)({unquote(prop_name), value}, path)
          end
        else
          quote do
            {unquote(prop_name), value} ->
              unquote(merged_call)({unquote(prop_name), value}, path)
          end
        end
      end

    # Generate pattern property dispatch
    pattern_checks =
      for {pattern, _index, pattern_pointer, _schema} <- registry.pattern_properties do
        pattern_call = Tools.call(resource, pattern_pointer, Context.scrub_opts(opts))
        compiled = Regex.compile!(pattern)
        escaped_regex = Macro.escape(compiled)

        if opts[:tracked] do
          quote do
            if Regex.match?(unquote(escaped_regex), key) do
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
            if Regex.match?(unquote(escaped_regex), key) do
              unquote(pattern_call)(value, Path.join(path, key))
            else
              :ok
            end
          end
        end
      end

    # Build the combined pattern check
    combined_pattern_check =
      case pattern_checks do
        [] ->
          if opts[:tracked] do
            quote do: {:ok, false}
          else
            :ok
          end

        [single] ->
          single

        multiple ->
          # Chain pattern checks - all must pass for allOf
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

    # Default clause for properties not in the merged set
    default_clause =
      if opts[:tracked] do
        quote do
          {_key, _value} -> {:ok, false}
        end
      else
        quote do
          {_key, _value} -> :ok
        end
      end

    # Build the iterator function
    if opts[:tracked] do
      quote do
        defp unquote(iterator_call)(object, path) do
          require Exonerate.Tools

          Enum.reduce_while(object, {:ok, MapSet.new()}, fn
            {key, value}, {:ok, seen} ->
              visited = false

              result =
                case {key, value} do
                  unquote_splicing(List.flatten(property_clauses))
                  unquote(default_clause)
                end

              case result do
                {:ok, prop_visited} ->
                  # Also check pattern properties
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
              result =
                case {key, value} do
                  unquote_splicing(List.flatten(property_clauses))
                  unquote(default_clause)
                end

              case result do
                :ok ->
                  # Also check pattern properties
                  {:cont, unquote(combined_pattern_check)}

                Exonerate.Tools.error_match(error) ->
                  {:halt, error}
              end
          end)
        end
      end
    end
  end
end
