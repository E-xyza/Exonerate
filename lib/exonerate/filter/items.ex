defmodule Exonerate.Filter.Items do
  @moduledoc false
  
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :schema, :additional_items, :prefix_size]

  def parse(artifact = %{context: context}, %{"items" => true}) do
    # true means any array is valid
    # this header clause is provided as an optimization.
    %{artifact | filters: [%__MODULE__{context: context, schema: true} | artifact.filters]}
  end

  def parse(artifact = %{context: context}, schema = %{"items" => false}) do
    # false means everything after prefixItems gets checked.
    if prefix_items = schema["prefixItems"] do
      filter = %__MODULE__{context: context, schema: false, prefix_size: length(prefix_items)}
      %{artifact |
        needs_accumulator: true,
        accumulator_pipeline: [fun(artifact, "items") | artifact.accumulator_pipeline],
        accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
        filters: [filter  | artifact.filters]}
    else
      # this is provided as an optimization.
      filter = %__MODULE__{context: context, schema: false, prefix_size: 0}
      %{artifact | filters: [filter]}
    end
  end

  def parse(artifact = %{context: context}, %{"items" => s}) when is_map(s) do
    fun = fun(artifact, "items")

    schema = Validator.parse(context.schema,
      ["items" | context.pointer],
      authority: context.authority,
      format_options: context.format_options)

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [
        %__MODULE__{
          context: context,
          schema: schema} | artifact.filters]}
  end

  def parse(artifact = %{context: context}, %{"items" => s}) when is_list(s) do
    fun = fun(artifact, "items")

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(context.schema,
        ["#{&1}", "items" | context.pointer],
        authority: context.authority,
        format_options: context.format_options))

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [
        %__MODULE__{
          context: artifact.context,
          schema: schemas,
          additional_items: artifact.additional_items} | artifact.filters]}
  end

  def compile(%__MODULE__{schema: true}), do: {[], []}

  def compile(filter = %__MODULE__{schema: false, prefix_size: 0}) do
    {[quote do
      defp unquote(fun(filter, []))(array, path) when is_list(array) and array != [] do
        Exonerate.mismatch(array, path, guard: "items")
      end
    end], []}
  end

  def compile(filter = %__MODULE__{schema: false}) do
    {[], [
      quote do
        defp unquote(fun(filter, "items"))(acc = %{index: index}, {path, array})
          when index < unquote(filter.prefix_size) do
          acc
        end
        defp unquote(fun(filter, "items"))(%{index: index}, {path, array}) do
          Exonerate.mismatch(array, path, guard: to_string(index))
        end
      end
    ]}
  end

  def compile(filter = %__MODULE__{schema: schema}) when is_map(schema) do
    {[], [
      quote do
        defp unquote(fun(filter, "items"))(acc, {path, item}) do
          unquote(fun(filter, "items"))(item, Path.join(path, to_string(acc.index)))
          acc
        end
        unquote(Validator.compile(schema))
      end
    ]}
  end

  def compile(filter = %__MODULE__{schema: schemas}) when is_list(schemas) do
    {trampolines, children} = schemas
    |> Enum.with_index()
    |> Enum.map(fn {schema, index} ->
      {quote do
        defp unquote(fun(filter, "items"))(acc = %{index: unquote(index)}, {path, item}) do
          unquote(fun(filter, ["items", to_string(index)]))(item, Path.join(path, unquote("#{index}")))
          acc
        end
      end,
      Validator.compile(schema)}
    end)
    |> Enum.unzip()

    additional_item_filter = if filter.additional_items do
      quote do
        defp unquote(fun(filter, "items"))(acc = %{index: index}, {path, item}) do
          unquote(fun(filter, "additionalItems"))(item, Path.join(path, to_string(index)))
          acc
        end
      end
    else
      quote do
        defp unquote(fun(filter, "items"))(acc = %{index: _}, {_item, _path}), do: acc
      end
    end

    {[], trampolines ++ [additional_item_filter] ++ children}
  end
end
