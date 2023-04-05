defmodule :"unevaluatedProperties false-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{type: "object", unevaluatedProperties: false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
