defmodule :"propertyNames with boolean schema false-gpt-3.5" do
  def validate(object) when is_map(object) and Map.size(object) > 0 do
    case Map.keys(object) do
      [_ | _] -> :error
      [] -> :ok
    end
  end

  def validate(_) do
    :ok
  end
end