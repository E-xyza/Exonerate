defmodule Exonerate.Filter.Properties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, :children, :evaluated_tokens]

  def parse(filter = %{context: context}, %{"properties" => properties}) do
    children =
      Map.new(
        properties,
        fn {k, _} ->
          {k,
           Context.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["properties", k]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
        end
      )

    %{
      filter
      | iterate: true,
        filters: [filter_from(filter, children) | filter.filters],
        kv_pipeline: [fun(filter, "properties") | filter.kv_pipeline]
    }
  end

  defp filter_from(filter = %{context: context}, children) do
    %__MODULE__{
      context: context,
      children: children,
      evaluated_tokens: filter.evaluated_tokens ++ context.evaluated_tokens
    }
  end

  def compile(filter = %__MODULE__{children: children}) do
    {guarded_clauses, tests} =
      children
      |> Enum.map(fn {k, v} ->
        {quote do
           defp unquote(fun(filter, "properties"))(_, {path, unquote(k), v}) do
             unquote(fun(filter, ["properties", k]))(v, Path.join(path, unquote(k)))

             require Exonerate.Filter.UnevaluatedHelper

             Exonerate.Filter.UnevaluatedHelper.register_tokens(
               unquote(filter.evaluated_tokens),
               unquote(k)
             )

             true
           end
         end, Context.compile(v)}
      end)
      |> Enum.unzip()

    {[],
     guarded_clauses ++
       [
         quote do
           defp unquote(fun(filter, "properties"))(seen, {_path, _key, _value}) do
             seen
           end
         end
       ] ++ tests}
  end
end
