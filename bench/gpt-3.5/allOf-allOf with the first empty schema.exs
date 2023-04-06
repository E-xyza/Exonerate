defmodule :"allOf-allOf with the first empty schema-gpt-3.5" do
  def validate(%{} = map) do
    case Map.keys(map) do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end