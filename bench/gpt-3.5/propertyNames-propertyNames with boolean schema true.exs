defmodule :"propertyNames with boolean schema true-gpt-3.5" do
  def validate(object) when is_map(object) do
    case(Map.keys(object), :propertyNames) do
      {[], true} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end