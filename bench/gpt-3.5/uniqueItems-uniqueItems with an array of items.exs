defmodule :"uniqueItems-uniqueItems with an array of items" do
  
defmodule MyModule do
  def validate(json) when is_map(json) do
    case Map.get(json, "prefixItems") do
      [{type: "boolean"}, {type: "boolean"}] ->
        case Map.get(json, "uniqueItems") do
          true -> :ok
          _ -> :error
        end
      _ -> :error
    end
  end

  def validate(_), do: :error
end

end
