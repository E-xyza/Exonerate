defmodule :"naive replacement of $ref with its destination is not correct" do
  def validate(json) do
    case is_a_string(json) do
      true -> :ok
      false -> {:error, "Invalid JSON value"}
    end
  end

  defp is_a_string(value) when is_binary(value), do: true
  defp is_a_string(_), do: false
end
