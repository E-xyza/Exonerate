defmodule Exonerate.Filter.PrefixItems do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :schema, :additional_items]

  def parse(artifact = %{context: context}, %{"prefixItems" => s}) when is_list(s) do
    schemas = Enum.map(0..(length(s) - 1),
      &Validator.parse(context.schema,
        ["#{&1}", "prefixItems" | context.pointer],
        authority: context.authority,
        format: context.format))

    %{artifact |
      needs_accumulator: true,
      accumulator_pipeline: [fun(artifact, "prefixItems") | artifact.accumulator_pipeline],
      accumulator_init: Map.put(artifact.accumulator_init, :index, 0),
      filters: [
        %__MODULE__{
          context: artifact.context,
          schema: schemas,
          additional_items: artifact.additional_items} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{schema: schemas}) when is_list(schemas) do
    {trampolines, children} = schemas
    |> Enum.with_index()
    |> Enum.map(fn {schema, index} ->
      {quote do
        defp unquote(fun(filter, "prefixItems"))(acc = %{index: unquote(index)}, {path, item}) do
          unquote(fun(filter, ["prefixItems", to_string(index)]))(item, Path.join(path, unquote("#{index}")))
          acc
        end
      end,
      Validator.compile(schema)}
    end)
    |> Enum.unzip()

    additional_item_filter = if filter.additional_items do
      quote do
        defp unquote(fun(filter, "prefixItems"))(acc = %{index: index}, {path, item}) do
          unquote(fun(filter, "additionalItems"))(item, Path.join(path, to_string(index)))
          acc
        end
      end
    else
      quote do
        defp unquote(fun(filter, "prefixItems"))(acc = %{index: _}, {_item, _path}), do: acc
      end
    end

    {[], trampolines ++ [additional_item_filter] ++ children}
  end
end
