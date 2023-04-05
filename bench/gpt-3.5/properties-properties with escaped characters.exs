defmodule :"properties with escaped characters" do
  
defmodule :"properties-properties with escaped characters" do
  def validate(schema) do
    case schema do
      %{"type" => "object"} ->
        fn map when is_map(map) -> :ok
           _ -> :error
        end
      %{"properties" => properties} ->
        fun =
          properties
          |> Enum.reduce([], fn {key, value}, acc ->
            module_name =
              key
              |> String.replace(~r/[\n\r\t\f"\\]/, &("\\\\" <> to_string(&1)) |> String.to_atom)

            schema = %{key => value}

            quote bind_quoted: [module_name: module_name, schema: schema, acc: acc] do
              def validate(unquote(module_name) = map when is_map(map) and map_contains?(unquote(map), unquote(schema)), do: Enum.concat(unquote(acc), [])

              def validate(map when is_map(map) and not map_contains?(unquote(map), unquote(schema)), do: [:error | Enum.concat(unquote(acc), []))
            end
          end)
          |> List.flatten()
          |> Macro.escape()

        Macro.module_eval(quote bind_quoted: [fun: fun] do
          def validate(map) do
            unquote(fun).(map)
          end
        end)
      _ ->
        fn _ -> :error end
    end
  end

  defp map_contains?(map, schema) do
    map
    |> Map.keys()
    |> Enum.all?(fn key -> schema_contains_key?(key, schema) end)
  end

  defp schema_contains_key?(key, schema) do
    case schema do
      %{"properties" => properties} ->
        Enum.any?(properties, fn {k, _} -> k == key end)
      _ ->
        false
    end
  end
end

end
