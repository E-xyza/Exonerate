defmodule :"propertyNames-propertyNames with boolean schema true-gpt-3.5" do
  def validate(object) when is_map(object) do
    cond do
      contains_only_valid_property_names?(object) -> :ok
      true -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp contains_only_valid_property_names?(object) do
    object |> Map.keys() |> Enum.all?(&valid_property_name?/1)
  end

  defp valid_property_name?(name) do
    case name do
      "" -> false
      _ -> true
    end
  end
end
