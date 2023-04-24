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

  @spec mode(Type.json()) :: FindIterator | FilterIterator | nil
  def mode(context) do
    context
    |> Map.take(@filters)
    |> case do
      empty when empty === %{} -> nil
      # the following filters must "go to completion".
      %{"items" => %{}} -> FilterIterator
      %{"items" => boolean} when is_boolean(boolean) -> FilterIterator
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

  # The iterator can have different number of call parameters depending on
  # which filters the context applies.  The following call parameters are
  # ALWAYS present:
  #
  # - full array
  # - remaining array
  # - path
  #
  # the following parameters are otional, and in the following order.  Their
  # use in the iterator depends on which iterator mode (filter/find) is selected,
  # and which filters are present.
  #
  # The args/2 function generates a canonical set of arguments for these values,
  # with an atom when it needs to be a variable and a number when it needs to be
  # a specific value.
  #
  # - index
  # - contains_count
  # - first_unseen_index
  # - unique_items

  @initial_args [:array, :array, :path, 0, 0, :first_unseen_index, :unique_items]
  def args(context) do
    select(context, @initial_args)
  end

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    execution_mode = mode(context)

    [
      quote do
        require unquote(execution_mode)
        unquote(execution_mode).filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    ]
  end

  def select(context, parameters) do
    if mode = mode(context) do
      mode.select(context, parameters)
    end
  end

  defmacro accessories(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_accessories(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
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
