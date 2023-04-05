defmodule :"nested unevaluatedProperties, outer false, inner true, properties inside-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) do
      [:foo | _] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end