defmodule Exonerate.Filter.Properties do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :children, :unevaluated_token]

  def parse(artifact = %{context: context}, %{"properties" => properties}) do
    children =
      Map.new(
        properties,
        fn {k, _} ->
          {k,
           Validator.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["properties", k]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
        end
      )

    %{
      artifact
      | iterate: true,
        filters: [filter_from(artifact, children) | artifact.filters],
        kv_pipeline: [fun(artifact, "properties") | artifact.kv_pipeline]
    }
  end

  defp filter_from(artifact, children) do
    %__MODULE__{
      context: artifact.context,
      children: children,
      unevaluated_token: artifact.unevaluated_token
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

             Exonerate.Filter.UnevaluatedHelper.register_key(
               unquote(filter.unevaluated_token),
               unquote(k)
             )

             true
           end
         end, Validator.compile(v)}
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
