defmodule :"allOf-allOf-gpt-3.5" do
  def validate(json) when is_map(json) do
    case Map.has_key?(json, "bar") and is_integer(Map.get(json, "bar")) do
      true ->
        case Map.has_key?(json, "foo") and is_binary(Map.get(json, "foo")) do
          true -> :ok
          false -> :error
        end

      false ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
