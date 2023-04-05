defmodule :"oneOf-oneOf complex types" do
  def validate(object) when is_map(object) do
    case Enum.filter([:bar, :foo], &Map.has_key?(object, &1)) do
      [:bar] ->
        case Map.fetch(object, :bar) do
          {:ok, value} when is_integer(value) -> :ok
          _ -> :error
        end
      [:foo] ->
        case Map.fetch(object, :foo) do
          {:ok, value} when is_binary(value) -> :ok
          _ -> :error
        end
      _ -> :error
    end
  end

  def validate(_), do: :error
end
