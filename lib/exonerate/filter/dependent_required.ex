defmodule Exonerate.Filter.DependentRequired do
  @moduledoc false

  # NB "dependentRequired" is just a repackaging of "dependencies" except only permitting the
  # array form ("other keys")

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type.Object
  alias Exonerate.Context

  defstruct [:context, :dependencies]

  def parse(filter = %{context: context}, %{"dependentRequired" => deps}) do
    deps =
      Map.new(deps, fn
        {k, list} when is_list(list) ->
          {k, list}
      end)

    %{
      filter
      | pipeline: ["dependentRequired" | filter.pipeline],
        filters: [%__MODULE__{context: context, dependencies: deps} | filter.filters]
    }
  end

  def compile(filter = %__MODULE__{dependencies: deps}) do
    {pipeline, children} =
      deps
      |> Enum.map(fn
        # one item optimization
        {key, [dependent_key]} ->
          {["dependentRequired", key],
           quote do
             defp unquote(["dependentRequired", key])(value, path)
                  when is_map_key(value, unquote(key)) do
               unless is_map_key(value, unquote(dependent_key)) do
                 Exonerate.mismatch(value, path, guard: "0")
               end

               value
             end

             defp unquote(["dependentRequired", key])(value, _), do: value
           end}

        {key, dependent_keys} when is_list(dependent_keys) ->
          {["dependentRequired", key],
           quote do
             defp unquote(["dependentRequired", key])(value, path)
                  when is_map_key(value, unquote(key)) do
               unquote(dependent_keys)
               |> Enum.with_index()
               |> Enum.each(fn {key, index} ->
                 unless is_map_key(value, key),
                   do: Exonerate.mismatch(value, path, guard: to_string(index))
               end)

               value
             end

             defp unquote(["dependentRequired", key])(value, _), do: value
           end}
      end)
      |> Enum.unzip()

    {[],
     [
       quote do
         defp unquote("dependentRequired")(value, path) do
           Exonerate.pipeline(value, path, unquote(pipeline))
           :ok
         end
       end
     ] ++ children}
  end
end
