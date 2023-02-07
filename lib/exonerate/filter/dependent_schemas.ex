defmodule Exonerate.Filter.DependentSchemas do
  @moduledoc false

  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of full schema to be applied to the object)

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Context
  defstruct [:context, :dependencies]

  import Context, only: [fun: 2]

  def parse(filter = %Object{context: context}, %{"dependentSchemas" => deps}) do
    deps =
      deps
      # as an optimization, just ignore {key, true}
      |> Enum.reject(&(elem(&1, 1) == true))
      |> Map.new(fn
        # might be optimizable as a filter.  Not done here.
        {k, false} ->
          {k, false}

        {k, schema} when is_map(schema) ->
          {k,
           Context.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["dependentSchemas", k]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
      end)

    %{
      filter
      | pipeline: [fun(filter, "dependentSchemas") | filter.pipeline],
        filters: [%__MODULE__{context: context, dependencies: deps} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} =
      deps
      |> Enum.map(fn
        {key, false} ->
          {fun(filter, ["dependentSchemas", key]),
           quote do
             defp unquote(fun(filter, ["dependentSchemas", key]))(value, path)
                  when is_map_key(value, unquote(key)) do
               Exonerate.mismatch(value, Path.join(path, unquote(key)))
             end

             defp unquote(fun(filter, ["dependentSchemas", key]))(value, _), do: value
           end}

        {key, schema} ->
          {fun(filter, ["dependentSchemas", ":" <> key]),
           quote do
             defp unquote(fun(filter, ["dependentSchemas", ":" <> key]))(value, path)
                  when is_map_key(value, unquote(key)) do
               unquote(fun(filter, ["dependentSchemas", key]))(value, path)
             end

             defp unquote(fun(filter, ["dependentSchemas", ":" <> key]))(value, _), do: value
             unquote(Context.compile(schema))
           end}
      end)
      |> Enum.unzip()

    {[],
     [
       quote do
         defp unquote(fun(filter, "dependentSchemas"))(value, path) do
           Exonerate.pipeline(value, path, unquote(pipeline))
           :ok
         end
       end
     ] ++ children}
  end
end
