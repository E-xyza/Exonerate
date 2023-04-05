defmodule :"enum-enums in properties" do
  def validate(%{"bar" => "bar"} = object) do
    case Map.get(object, "foo") do
      "foo" -> :ok
      nil -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
