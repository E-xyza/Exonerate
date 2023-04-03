defmodule Exonerate.Degeneracy do
  @moduledoc false

  # module with code that deals with degenerate subschemas, as well as code that can be safely deleted.

  alias Exonerate.Tools
  alias Exonerate.Type

  @all_types Type.all()

  @spec canonicalize(Type.json(), keyword) :: Type.json()
  @doc """
  operates specifically on contexts, and works to canonicalize them.  This is
  performed when the schema is cached, so all

  Steps:

  1. prune filters which are redundant

  2. prune filters which are degenerate-ok.  Currently, degenerate-error
  filters are not pruned because they will be needed to generate correct
  error messages.

  3. combine filters that for performance reasons should be combined.
    - this is currently only minLength/maxLength for strings.

  4. recursively enter content that is a context

  5. always include a type filter, and make sure it's always an array

  Canonicalize recursively canonicalizes, also after searching refs.
  """

  @regex_all ["", ".*"]
  @ref_override_drafts ~w(4 5 6 7)

  def canonicalize(boolean, _opts) when is_boolean(boolean), do: boolean

  def canonicalize(source, opts) do
    draft = Keyword.get(opts, :draft)

    entrypoint = Tools.entrypoint(opts)

    opts = Keyword.delete(opts, :entrypoint)

    canonicalized = source
    |> JsonPointer.resolve_json!(entrypoint)
    |> canonicalize_recursive(opts)
    |> case do
      ## very trivial
      context when context === %{} ->
        true

      ## redundant filters
      %{"$ref" => ref} when draft in @ref_override_drafts ->
        # ref overrides all other filters in draft <= 7
        %{"$ref" => ref, "type" => @all_types}

      context = %{"maximum" => max, "exclusiveMaximum" => emax}
      when is_number(emax) and max >= emax ->
        canonicalize_purged(context, "maximum", opts)

      context = %{"minimum" => min, "exclusiveMinimum" => emin}
      when is_number(emin) and min <= emin ->
        canonicalize_purged(context, "minimum", opts)

      context = %{"maxContains" => _} when not is_map_key(context, "contains") ->
        canonicalize_purged(context, "maxContains", opts)

      context = %{"minContains" => _} when not is_map_key(context, "contains") ->
        canonicalize_purged(context, "minContains", opts)

      context = %{"if" => _}
      when not is_map_key(context, "then") and not is_map_key(context, "else") ->
        canonicalize_purged(context, "if", opts)

      context = %{"exclusiveMinimum" => true} when not is_map_key(context, "minimum") ->
        canonicalize_purged(context, "exclusiveMinimum", opts)

      context = %{"exclusiveMaximum" => true} when not is_map_key(context, "maximum") ->
        canonicalize_purged(context, "exclusiveMaximum", opts)

      ## degenerate-OK filters
      context = %{"exclusiveMinimum" => false} ->
        canonicalize_purged(context, "exclusiveMinimum", opts)

      context = %{"exclusiveMaximum" => false} ->
        canonicalize_purged(context, "exclusiveMaximum", opts)

      context = %{"propertyNames" => true} ->
        canonicalize_purged(context, "propertyNames", opts)

      context = %{"uniqueItems" => false} ->
        canonicalize_purged(context, "uniqueItems", opts)

      context = %{"minLength" => 0} ->
        canonicalize_purged(context, "minLength", opts)

      context = %{"minItems" => 0} ->
        canonicalize_purged(context, "minItems", opts)

      context = %{"minProperties" => 0} ->
        canonicalize_purged(context, "minProperties", opts)

      context = %{"minContains" => 0, "contains" => _}
      when not is_map_key(context, "maxContains") ->
        canonicalize_purged(context, ["minContains", "contains"], opts)

      context = %{"pattern" => regex_all} when regex_all in @regex_all ->
        # this is not comprehensive, but it's good enough for a first pass.
        canonicalize_purged(context, "pattern", opts)

      context = %{"additionalItems" => _} when not is_map_key(context, "items") ->
        canonicalize_purged(context, "additionalItems", opts)

      context = %{"additionalItems" => _, "items" => items}
      when is_map(items) or is_boolean(items) ->
        canonicalize_purged(context, "additionalItems", opts)

      context = %{"unevaluatedItems" => _, "items" => items}
      when is_map(items) or is_boolean(items) ->
        canonicalize_purged(context, "unevaluatedItems", opts)

      ### empty filter lists
      context = %{"required" => []} ->
        canonicalize_purged(context, "required", opts)

      context = %{"allOf" => []} ->
        canonicalize_purged(context, "allOf", opts)

      # combine minLength and maxLength
      context = %{"minLength" => min, "maxLength" => max} ->
        # note the min-max-length string doesn't look like a normal JsonSchema filter.
        context
        |> Map.put("min-max-length", [min, max])
        |> canonicalize_purged(["minLength", "maxLength"], opts)

      ## type normalization
      context = %{"type" => type} when is_binary(type) ->
        context
        |> Map.put("type", [type])
        |> canonicalize(opts)

      context when not is_map_key(context, "type") ->
        canonicalize_no_type(context, opts)

      ## const and enum normalization
      context = %{"const" => const, "enum" => enum} ->
        if const in enum do
          canonicalize_purged(context, "enum", opts)
        else
          context
        end

      context ->
        context
    end
    |> canonicalize_finalize

    JsonPointer.update_json!(source, entrypoint, fn _ -> canonicalized end)
  end

  defp canonicalize_purged(context, what, opts) when is_binary(what) do
    context
    |> Map.delete(what)
    |> canonicalize(opts)
  end

  defp canonicalize_purged(context, what, opts) when is_list(what) do
    context
    |> Map.drop(what)
    |> canonicalize(opts)
  end

  # canonicalize type statements
  defp canonicalize_no_type(context, opts) do
    # include a type statement when it's not present
    types =
      cond do
        const = context["const"] ->
          const
          |> Type.of()
          |> to_list_type

        enum = context["enum"] ->
          enum
          |> List.wrap()
          |> Enum.flat_map(&(&1 |> Type.of() |> to_list_type()))
          |> Enum.uniq()

        true ->
          @all_types
      end

    context
    |> Map.put("type", types)
    |> canonicalize(opts)
  end

  defp to_list_type("integer"), do: ["integer", "number"]
  defp to_list_type("number"), do: ["integer", "number"]
  defp to_list_type(type), do: [type]

  defp canonicalize_recursive(boolean, _) when is_boolean(boolean), do: boolean

  defp canonicalize_recursive(context, opts) when is_map(context) do
    context
    |> update("additionalItems", &canonicalize(&1, opts))
    |> update("additionalProperties", &canonicalize(&1, opts))
    |> update("contains", &canonicalize(&1, opts))
    |> update("dependencies", &canonicalize_dependencies(&1, opts))
    |> update("dependentSchemas", &canonicalize_object(&1, opts))
    |> update("items", &canonicalize_items(&1, opts))
    |> update("patternProperties", &canonicalize_object(&1, opts))
    |> update("prefixItems", &canonicalize_array(&1, opts))
    |> update("properties", &canonicalize_object(&1, opts))
    |> update("propertyNames", &canonicalize(&1, opts))
    |> update("unevaluatedItems", &canonicalize(&1, opts))
    |> update("unevaluatedProperties", &canonicalize(&1, opts))
    |> update("allOf", &canonicalize_array(&1, opts))
    |> update("anyOf", &canonicalize_array(&1, opts))
    |> update("oneOf", &canonicalize_array(&1, opts))
    |> update("not", &canonicalize(&1, opts))
    |> update("if", &canonicalize(&1, opts))
    |> update("then", &canonicalize(&1, opts))
    |> update("else", &canonicalize(&1, opts))
  end

  defp update(map, key, fun) when is_map_key(map, key), do: Map.update!(map, key, fun)
  defp update(map, _key, _fun), do: map

  defp canonicalize_items(boolean, _pts) when is_boolean(boolean), do: boolean
  defp canonicalize_items(array, opts) when is_list(array), do: canonicalize_array(array, opts)
  defp canonicalize_items(object, opts) when is_map(object), do: canonicalize(object, opts)

  defp canonicalize_dependencies(object, opts) do
    Map.new(object, fn
      {k, v} when is_map(v) -> {k, canonicalize(v, opts)}
      kv -> kv
    end)
  end

  defp canonicalize_object(object, opts),
    do: Map.new(object, fn {k, v} -> {k, canonicalize(v, opts)} end)

  defp canonicalize_array(array, opts), do: Enum.map(array, &canonicalize(&1, opts))

  defp canonicalize_finalize(boolean) when is_boolean(boolean), do: boolean

  defp canonicalize_finalize(context) do
    Map.update!(context, "type", &cleanup_types/1)
  end

  def cleanup_types(types) do
    if "number" in types do
      ["integer" | types]
    else
      types
    end
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec class(Type.json()) :: :ok | :error | :unknown
  def class(true), do: :ok
  def class(false), do: :error

  def class(subschema = %{"type" => t}) do
    if Enum.sort(List.wrap(t)) in @all_types do
      subschema
      |> Map.delete("type")
      |> class()
      |> matches(true)
    else
      :unknown
    end
  end

  def class(subschema = %{"not" => not_schema}) do
    rest =
      subschema
      |> Map.delete("not")
      |> class

    case class(not_schema) do
      :ok when rest === :error -> :error
      :error when rest === :ok -> :ok
      _ -> :unknown
    end
  end

  def class(subschema = %{"allOf" => list}) do
    rest_degeneracy =
      subschema
      |> Map.delete("allOf")
      |> class

    list
    |> Enum.map(&class/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_degeneracy

      [:ok] ->
        matches(rest_degeneracy, true)

      [:error] ->
        matches(rest_degeneracy, false)

      _ ->
        :unknown
    end
  end

  def class(subschema = %{"anyOf" => list}) do
    rest_degeneracy =
      subschema
      |> Map.delete("anyOf")
      |> class

    list
    |> Enum.map(&class/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_degeneracy

      [:error] ->
        matches(rest_degeneracy, false)

      list ->
        if :ok in list do
          matches(rest_degeneracy, true)
        else
          :unknown
        end
    end
  end

  def class(subschema = %{"minItems" => 0}) do
    subschema
    |> Map.delete("minItems")
    |> class
  end

  def class(subschema = %{"minProperties" => 0}) do
    subschema
    |> Map.delete("minProperties")
    |> class
  end

  def class(subschema = %{"minContains" => 0}) do
    subschema
    |> Map.delete("minContains")
    |> class
  end

  def class(empty_map) when empty_map == %{} do
    :ok
  end

  def class(_), do: :unknown

  defp matches(value, rest_schema) do
    case class(rest_schema) do
      ^value -> value
      _ -> :unknown
    end
  end

  # general convenience functions
  def if(item, boolean, predicate) do
    if boolean do
      predicate.(item)
    else
      item
    end
  end
end
