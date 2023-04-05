defmodule :"invalid type for default-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(map) do
    case Map.has_key?(map, "foo") do
      true ->
        case validate_foo(Map.get(map, "foo")) do
          :ok -> :ok
          _ -> :error
        end

      false ->
        :ok
    end
  end

  defp validate_foo(foo) do
    case is_integer_list(foo) do
      true -> :ok
      _ -> :error
    end
  end

  defp is_integer_list(list) do
    list == [] or (is_list(list) and Enum.all?(list, &is_integer/1))
  end
end