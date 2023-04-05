defmodule :"properties-properties with boolean schema" do
  def validate(object) when is_map(object) do
    properties_valid? = validate_properties(object)

    if properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_properties(%{"foo" => foo, "bar" => _}) do
    foo == true
  end
  defp validate_properties(%{"foo" => foo}), do: foo == true
  defp validate_properties(%{"bar" => _}), do: false
  defp validate_properties(%{}), do: true
end
