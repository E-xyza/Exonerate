defmodule :"allOf-allOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_inner1(object) do
      :ok -> validate_inner2(object)
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_inner1(object) do
    case Map.has_key?(object, "foo") and is_integer(Map.get(object, "foo")) do
      true -> :ok
      _ -> :error
    end
  end

  defp validate_inner2(object) do
    case Map.has_key?(object, "foo") and is_binary(Map.get(object, "foo")) do
      true -> :ok
      _ -> :error
    end
  end
end
