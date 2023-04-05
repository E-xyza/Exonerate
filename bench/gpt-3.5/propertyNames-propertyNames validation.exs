defmodule :"propertyNames-propertyNames validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    case check_property_names(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  def check_property_names(object) do
    case Map.keys(object) |> Enum.map(&String.length/1) |> Enum.all(&(&1 <= 3)) do
      true -> true
      false -> false
    end
  end
end
