defmodule :"oneOf-oneOf with empty schema-gpt-3.5" do
  def validate(value) do
    case value do
      %{"type" => "number"} -> :ok
      %{} -> :ok
      _ -> :error
    end
  end
end