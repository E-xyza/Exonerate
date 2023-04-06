defmodule :"allOf-allOf with base schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_schema1(object) do
      :ok -> validate_schema2(object)
      :error -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_schema1(object) do
    case Map.fetch(object, "foo") do
      {:ok, value} when is_binary(value) -> :ok
      _ -> :error
    end
  end

  defp validate_schema1(_) do
    :error
  end

  defp validate_schema2(object) do
    case Map.fetch(object, "baz") do
      {:ok, value} when is_nil(value) -> :ok
      _ -> :error
    end
    |> case do
      :ok -> validate_schema3(object)
      :error -> :error
    end
  end

  defp validate_schema3(object) do
    case Map.fetch(object, "bar") do
      {:ok, value} when is_integer(value) -> :ok
      _ -> :error
    end
  end
end