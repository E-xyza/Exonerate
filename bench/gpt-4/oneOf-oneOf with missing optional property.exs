defmodule :"oneOf with missing optional property" do
  def validate(%{"foo" => _} = object) do
    case Map.keys(object) do
      ["foo"] -> :ok
      _ -> :error
    end
  end
  def validate(%{"bar" => _} = object) do
    case Map.keys(object) do
      ["bar", "baz"] -> :ok
      _ -> :error
    end
  end
  def validate(_), do: :error
end
