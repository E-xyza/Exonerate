defmodule :"exclusiveMinimum validation-gpt-3.5" do
  def validate(object) when is_map(object) and Map.get(object, "exclusiveMinimum", 0) >= 1.1 do
    :ok
  end

  def validate(_) do
    :error
  end
end
