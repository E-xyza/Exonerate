defmodule :"oneOf-oneOf with empty schema-gpt-3.5" do
  def validate(%{"oneOf" => one_of}) when is_list(one_of) do
    case length(one_of) do
      2 ->
        [first, second] = one_of

        case {first["type"], second} do
          {"number", %{} = map} when is_number(Map.get(map, "number")) -> :ok
          {_, %{} = map} when Map.is_empty(map) -> :ok
          _ -> :error
        end

      1 ->
        [schema] = one_of

        case schema["type"] do
          "number" -> :error
          _ -> :ok
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
