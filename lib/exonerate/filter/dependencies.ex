defmodule Exonerate.Filter.Dependencies do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Context

  defstruct [:context, :dependencies]

  def parse(filter = %{context: context}, %{"dependencies" => deps}) do
    deps =
      deps
      # as an optimization, just ignore {key, true}
      |> Enum.reject(&(elem(&1, 1) == true))
      |> Map.new(fn
        # might be optimizable as a filter.  Not done here.
        {k, false} ->
          {k, false}

        {k, list} when is_list(list) ->
          {k, list}

        {k, schema} when is_map(schema) ->
          {k,
           Context.parse(
             context.schema,
             JsonPointer.traverse(context.pointer, ["dependencies", k]),
             authority: context.authority,
             format: context.format,
             draft: context.draft
           )}
      end)

    %{
      filter
      | pipeline: ["dependencies" | filter.pipeline],
        filters: [%__MODULE__{context: context, dependencies: deps} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} =
      deps
      |> Enum.map(fn
        {key, false} ->
          {["dependencies", key],
           quote do
             defp unquote(["dependencies", key])(value, path)
                  when is_map_key(value, unquote(key)) do
               Exonerate.mismatch(value, Path.join(path, unquote(key)))
             end

             defp unquote(["dependencies", key])(value, _), do: value
           end}

        # one item optimization
        {key, [dependent_key]} ->
          {["dependencies", key],
           quote do
             defp unquote(["dependencies", key])(value, path)
                  when is_map_key(value, unquote(key)) do
               unless is_map_key(value, unquote(dependent_key)) do
                 Exonerate.mismatch(value, path, guard: "0")
               end

               value
             end

             defp unquote(["dependencies", key])(value, _), do: value
           end}

        {key, dependent_keys} when is_list(dependent_keys) ->
          {["dependencies", key],
           quote do
             defp unquote(["dependencies", key])(value, path)
                  when is_map_key(value, unquote(key)) do
               unquote(dependent_keys)
               |> Enum.with_index()
               |> Enum.each(fn {key, index} ->
                 unless is_map_key(value, key),
                   do: Exonerate.mismatch(value, path, guard: to_string(index))
               end)

               value
             end

             defp unquote(["dependencies", key])(value, _), do: value
           end}

        {key, schema} ->
          {["dependencies", ":" <> key],
           quote do
             defp unquote(["dependencies", ":" <> key])(value, path)
                  when is_map_key(value, unquote(key)) do
               unquote(["dependencies", key])(value, path)
             end

             defp unquote(["dependencies", ":" <> key])(value, _), do: value
             unquote(Context.compile(schema))
           end}
      end)
      |> Enum.unzip()

    {[],
     [
       quote do
         defp unquote("dependencies")(value, path) do
           Exonerate.pipeline(value, path, unquote(pipeline))
           :ok
         end
       end
     ] ++ children}
  end
end
