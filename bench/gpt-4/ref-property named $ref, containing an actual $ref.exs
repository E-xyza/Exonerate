defmodule :"ref-property named $ref, containing an actual $ref" do
  def validate(value) do
    case value do
      %{"$ref" => string_value} ->
        validate_is_string(string_value)

      %{} ->
        :ok

      _ ->
        {:error, "Invalid value"}
    end
  end

  defp validate_is_string(value) when is_binary(value), do: :ok
  defp validate_is_string(_), do: {:error, "Invalid $ref value"}
end
