defmodule :"unevaluatedProperties with oneOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    result = validate_properties(object)

    case result do
      :ok -> validate_one_of(object)
      _ -> result
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(object) do
    case Map.get(object, "foo") do
      nil -> :error
      _ -> :ok
    end
  end

  defp validate_one_of(object) do
    one_of = [{"bar", "bar"}, {"baz", "baz"}]
    bar_or_baz = Enum.into(one_of, %{})
    required_keys = ["bar", "baz"]

    case Enum.any?(one_of, fn {key, value} -> Map.get(object, key) == value end) do
      true ->
        case Enum.all?(required_keys, fn key -> Map.has_key?(object, key) end) do
          true -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
