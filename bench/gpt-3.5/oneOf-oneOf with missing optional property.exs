defmodule :"oneOf with missing optional property-gpt-3.5" do
  def validate(json) when is_map(json) do
    validate_object(json)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{"foo" => _}) do
    :ok
  end

  defp validate_object(%{"bar" => _, "baz" => _}) do
    :ok
  end

  defp validate_object(_) do
    :error
  end
end