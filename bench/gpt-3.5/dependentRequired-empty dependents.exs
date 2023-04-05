defmodule :"dependentRequired-empty dependents-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "bar") do
      if Map.get(object, "bar") == [] do
        :ok
      else
        :error
      end
    else
      :ok
    end
  end

  def validate(_) do
    :error
  end
end
