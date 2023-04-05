defmodule :"allOf combined with anyOf, oneOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    multiple_of_2 =
      case Map.get(object, "multipleOf") do
        value when rem(value, 2) == 0 -> :ok
        _ -> :error
      end

    multiple_of_3 =
      case Map.get(object, "multipleOf") do
        value when rem(value, 3) == 0 -> :ok
        _ -> :error
      end

    multiple_of_5 =
      case Map.get(object, "multipleOf") do
        value when rem(value, 5) == 0 -> :ok
        _ -> :error
      end

    case {multiple_of_2, multiple_of_3, multiple_of_5} do
      {:ok, :error, :error} -> :ok
      {:error, :ok, :error} -> :ok
      {:error, :error, :ok} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end