defmodule :"additionalProperties allows a schema which should validate-gpt-3.5" do
  def validate(%{} = object) do
    case Map.keys(object) -- [:foo, :bar] do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end
