defmodule :"allOf with the last empty schema-gpt-3.5" do
  def validate(value) do
    case value do
      number when is_number(number) -> :ok
      map when is_map(map) -> :ok
      _ -> :error
    end
  end
end