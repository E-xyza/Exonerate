defmodule Exonerate.Degeneracy do
  @moduledoc false

  # module with code that deals with degenerate subschemas, as well as code that can be safely deleted.
  alias Exonerate.Type

  @all_types Type.all()

  @spec canonicalize(Type.json()) :: Type.json()
  @doc """
  operates specifically on contexts, and works to canonicalize them.

  This process includes three steps:

  1. prune filters which are redundant

  2. prune filters which are degenerate-ok.  Currently, degenerate-error
  filters are not pruned because they will be needed to generate correct
  error messages.

  3. always include a type filter, and make sure it's always an array

  NB: Canonicalize does not recursively canonicalize, it only performs
  local canonicalization
  """

  # redundant filters
  def canonicalize(context = %{"maximum" => max, "exclusiveMaximum" => emax}) when max >= emax do
    context
    |> Map.delete("maximum")
    |> canonicalize
  end

  def canonicalize(context = %{"minimum" => min, "exclusiveMinimum" => emin}) when min <= emin do
    context
    |> Map.delete("minimum")
    |> canonicalize
  end

  def canonicalize(context = %{"minContains" => _}) when not is_map_key(context, "contains") do
    context
    |> Map.delete("minContains")
    |> canonicalize
  end

  def canonicalize(context = %{"const" => _, "enum" => _}) do
    context
    |> Map.delete("enum")
    |> canonicalize
  end

  ## degenerate-OK filters

  def canonicalize(context = %{"minLength" => min}) when min == 0 do
    context
    |> Map.delete("minLength")
    |> canonicalize
  end

  # this is not comprehensive, but it's good enough for a first pass.
  @regex_all ["", ".*"]
  def canonicalize(context = %{"pattern" => regex_all}) when regex_all in @regex_all do
    context
    |> Map.delete("pattern")
    |> canonicalize
  end

  def canonicalize(context = %{"minItems" => min}) when min == 0 do
    context
    |> Map.delete("minItems")
    |> canonicalize
  end

  def canonicalize(context = %{"minContains" => min, "contains" => _}) when min == 0 do
    context
    |> Map.drop(["minContains", "contains"])
    |> canonicalize
  end

  def canonicalize(context = %{"minProperties" => min}) when min == 0 do
    context
    |> Map.delete("minProperties")
    |> canonicalize
  end

  def canonicalize(context = %{"required" => []}) do
    context
    |> Map.delete("required")
    |> canonicalize
  end

  def canonicalize(context = %{"type" => type}) when is_binary(type) do
    context
    |> Map.put("type", [type])
    |> canonicalize
  end

  def canonicalize(context) when not is_map_key(context, "type") do
    # include a type statement when it's not present
    types =
      cond do
        enum = context["enum"] ->
          enum
          |> List.wrap()
          |> Enum.map(&Type.of/1)
          |> Enum.uniq()

        const = context["const"] ->
          [Type.of(const)]

        true ->
          @all_types
      end

    context
    |> Map.put("type", types)
    |> canonicalize
  end

  def canonicalize(context), do: context

  @all_types_lists [
    ~w(array boolean integer null number object string),
    # you can skip integer because number subsumes it
    ~w(array boolean null number object string)
  ]

  @spec class(module, atom, JsonPointer.t()) :: :ok | :error | :unknown
  def class(module, name, pointer) do
    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> class
  end

  @spec class(Type.json()) :: :ok | :error | :unknown
  def class(true), do: :ok
  def class(false), do: :error

  def class(subschema = %{"type" => t}) do
    if Enum.sort(List.wrap(t)) in @all_types_lists do
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

  # tracking related
  def drop_tracking(opts) do
    Keyword.drop(opts, [:track_properties, :track_items])
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
