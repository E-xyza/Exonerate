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

  def needed?(context) do
    Enum.any?(@filters, &is_map_key(context, &1))
  end

  @find_key_sets [
    ["contains"],
    ["minItems"],
    ["contains", "minItems"],
    ["contains", "minContains"],
    ["contains", "minContains", "minItems"]
  ]

  @spec mode(Type.json(), keyword) :: FindIterator | FilterIterator | nil
  def mode(context, opts) do
    tracked = opts[:tracked]

    context
    |> Map.take(@filters)
    |> Map.keys()
    |> Enum.sort()
    |> case do
      [] -> nil
      keys when keys in @find_key_sets and is_nil(tracked) -> FindIterator
      _ -> FilterIterator
    end
  end

  def call(resource, pointer, opts) do
    Tools.call(resource, pointer, :array_iterator, opts)
  end

  def args(context, opts) do
    if mode = mode(context, opts) do
      mode.args(context, opts)
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
      if execution_mode = mode(context, opts) do
        quote do
          require unquote(execution_mode)
          unquote(execution_mode).filter(unquote(resource), unquote(pointer), unquote(opts))
        end
      end
    )
  end

  def select_params(context, parameters, opts) do
    if mode = mode(context, opts) do
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
