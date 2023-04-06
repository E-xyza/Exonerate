defmodule :"items-prefixItems with no additional items allowed-gpt-3.5" do
  def validate(object) when is_map(object), do: validate_object(object)
  def validate(_), do: :error

  defp validate_object(object) do
    case Map.has_key?(object, :items) and Map.has_key?(object, :prefixItems) and not Map.has_key?(object, :additionalItems) do
      true -> Map.get(object, :prefixItems)
              |> Enum.all?(fn _ -> %{} end)
              |> :json_schema.validate(:#{false})
              |> handle_validation_result()
      false -> :error
    end
  end

  defp handle_validation_result(result) do
    case result do
      {:ok, _} -> :ok
      {:error, _, _} -> :error
    end
  end
end
