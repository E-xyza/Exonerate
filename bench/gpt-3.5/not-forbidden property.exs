defmodule :"not-forbidden property-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(object) do
    case Map.has_key?(object, "foo") do
      true -> :error
      false -> :ok
    end
  end
end
