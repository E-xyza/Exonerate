defmodule :"additional items are allowed by default-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate([]) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp validate_map(object) do
    validate_object_type(object["prefixItems"])
  end

  defp validate_object_type(%{"type" => "object"}) do
    :ok
  end

  defp validate_object_type(_) do
    :error
  end
end
