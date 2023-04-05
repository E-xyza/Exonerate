defmodule :"empty dependents-gpt-3.5" do
  def validate(json) when is_map(json) do
    case get_in(json, ["dependentRequired", "bar"]) do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end