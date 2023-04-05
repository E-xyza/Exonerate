defmodule :"unevaluatedProperties with adjacent properties" do
  def validate(object) when is_map(object) do
    case Map.pop(object, "foo") do
      {"", rest} -> :error
      {nil, _} -> :error
      {value, rest} when is_binary(value) and Enum.empty?(rest) -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
