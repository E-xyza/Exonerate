defmodule :"oneOf-oneOf with required" do
  def validate(object) when is_map(object) do
    case Enum.count([:foo, :bar] -- Map.keys(object)) do
      0 -> :ok
      _ -> case Enum.count([:foo, :baz] -- Map.keys(object)) do
        0 -> :ok
        _ -> :error
      end
    end
  end

  def validate(_), do: :error
end
