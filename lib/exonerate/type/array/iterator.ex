defmodule Exonerate.Type.Array.Iterator do
  @moduledoc false

  # note that iteration can go in two different modes, "find" vs "filter". In
  # "filter" mode, the iteration will occur with the same objective as most
  # JsonSchema logic -- when an error is encountered, it terminates and
  # reports this error as the result.  In "find" mode, error is assumed and
  # the looping terminates when a passing result is found, this only applies
  # when the only filters are "minItems" and "contains" filters.

  alias Exonerate.Tools
  alias Exonerate.Type

  alias Exonerate.Type.Array.FindIterator
  alias Exonerate.Type.Array.FilterIterator

  @modules %{
    "items" => Exonerate.Filter.Items,
    "contains" => Exonerate.Filter.Contains,
    "uniqueItems" => Exonerate.Filter.UniqueItems,
    "minItems" => Exonerate.Filter.MinItems,
    "maxItems" => Exonerate.Filter.MaxItems,
    "additionalItems" => Exonerate.Filter.AdditionalItems,
    "prefixItems" => Exonerate.Filter.PrefixItems,
    "maxContains" => Exonerate.Filter.MaxContains,
    "minContains" => Exonerate.Filter.MinContains,
    "unevaluatedItems" => Exonerate.Filter.UnevaluatedItems
  }

  @context_filters ~w(items contains additionalItems prefixItems unevaluatedItems)

  @filters Map.keys(@modules)

  def filters, do: @filters

  @spec mode(Type.json()) :: FindIterator | FilterIterator | nil
  def mode(context) do
    context
    |> Map.take(@filters)
    |> case do
      empty when empty === %{} -> nil
      # the following filters must "go to completion".
      %{"items" => %{}} -> FilterIterator
      %{"maxContains" => _} -> FilterIterator
      %{"maxItems" => _} -> FilterIterator
      %{"uniqueItems" => true} -> FilterIterator
      %{"additionalItems" => _} -> FilterIterator
      %{"unevaluatedItems" => _} -> FilterIterator
      # everything else can be subjected to a find iterator
      _ -> FindIterator
    end
  end

  def call(resource, pointer, opts) do
    Tools.call(resource, pointer, :array_iterator, opts)
  end

  def args(context) do
    if mode = mode(context) do
      mode.args(context)
    end
  end

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    List.wrap(
      if execution_mode = mode(context) do
        quote do
          require unquote(execution_mode)
          unquote(execution_mode).filter(unquote(resource), unquote(pointer), unquote(opts))
        end
      end
    )
  end

  def select_params(context, parameters) do
    if mode = mode(context) do
      mode.select_params(context, parameters)
    end
  end

  defmacro accessories(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_accessories(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, resource, pointer, opts) do
    for filter <- @context_filters, is_map_key(context, filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).context(unquote(resource), unquote(pointer), unquote(opts))
      end
    end
  end
end
