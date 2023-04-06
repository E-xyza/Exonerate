defmodule :"additionalProperties-additionalProperties allows a schema which should validate-gpt-3.5" do
  def validate(%{additionalProperties: %{type: "boolean"}, properties: _} = object)
      when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end