defmodule :"property named $ref that is not a reference" do
  def validate(value) do
    case value do
      %{"$ref" => string_value} when is_binary(string_value) ->
        :ok

      %{} ->
        :ok

      _ ->
        {:error, "Invalid value"}
    end
  end
end
