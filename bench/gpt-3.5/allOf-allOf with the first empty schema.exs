defmodule :"allOf with the first empty schema-gpt-3.5" do
  def validate(value) do
    case value do
      %{} = map_val when is_map(map_val) -> :ok
      number_val when is_number(number_val) -> :ok
      _ -> :error
    end
  end
end
