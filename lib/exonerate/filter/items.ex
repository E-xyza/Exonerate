defmodule Exonerate.Filter.Items do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :schema, :type, :additional_items]

  def parse(artifact = %{context: context}, %{"items" => s}) when is_map(s) do
    fun = fun(artifact)

    schema = Validator.parse(context.schema,
      ["items" | context.pointer],
      authority: context.authority)

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [{fun, []} | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [
        %__MODULE__{
          context: context,
          schema: schema,
          type: :map} | artifact.filters]}
  end

  def parse(artifact = %{context: context}, %{"items" => s}) when is_list(s) do
    fun = fun(artifact)

    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(context.schema,
        ["#{&1}", "items" | context.pointer],
        authority: context.authority))

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [{fun, []} | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [
        %__MODULE__{
          context: artifact.context,
          schema: schemas,
          type: :list,
          additional_items: artifact.additional_items} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{schema: schema, type: :map}) do
    {[], [
      quote do
        defp unquote(fun(filter))(acc, {path, item}) do
          unquote(fun(filter))(item, Path.join(path, to_string(acc.index)))
          acc
        end
        unquote(Validator.compile(schema))
      end
    ]}
  end

  def compile(filter = %__MODULE__{schema: schemas, type: :list}) do
    {trampolines, children} = schemas
    |> Enum.with_index()
    |> Enum.map(fn {schema, index} ->
      {quote do
        defp unquote(fun(filter))(acc = %{index: unquote(index)}, {path, item}) do
          unquote(fun(filter, index))(item, Path.join(path, unquote("#{index}")))
          acc
        end
      end,
      Validator.compile(schema)}
    end)
    |> Enum.unzip()

    additional_item_filter = if filter.additional_items do
      quote do
        defp unquote(fun(filter))(acc = %{index: index}, {path, item}) do
          unquote(fun_a(filter))(item, Path.join(path, to_string(index)))
          acc
        end
      end
    else
      quote do
        defp unquote(fun(filter))(acc = %{index: _}, {_item, _path}), do: acc
      end
    end

    {[], trampolines ++ [additional_item_filter] ++ children}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("items")
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}, index) do
    filter_or_artifact.context
    |> Validator.jump_into("items")
    |> Validator.jump_into("#{index}")
    |> Validator.to_fun
  end

  defp fun_a(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("additionalItems")
    |> Validator.to_fun
  end
end
