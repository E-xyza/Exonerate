defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent patternProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) do
      [_ | _] -> :error
      [] -> :ok
    end
  end

  def validate(_) do
    :error
  end
end
