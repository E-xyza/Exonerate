defmodule :"required-required validation-gpt-3.5" do
  def validate(data) when is_map(data) do
    case Map.has_key?(data, "foo") do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end