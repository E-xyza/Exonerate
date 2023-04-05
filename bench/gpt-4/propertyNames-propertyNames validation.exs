defmodule :"propertyNames-propertyNames validation" do
  def validate(object) when is_map(object) do
    object
    |> Map.keys()
    |> Enum.map(&validate_property_name/1)
    |> Enum.all?(&(&1 == :ok))
    |> case do
      true -> :ok
      _ -> :error
    end
  end
  def validate(_), do: :error

  defp validate_property_name(property_name) do
    if String.length(property_name) <= 3 do
      :ok
    else
      :error
    end
  end
end
