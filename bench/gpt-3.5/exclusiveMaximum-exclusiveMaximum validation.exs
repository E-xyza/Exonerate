defmodule :"exclusiveMaximum validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.get(object, "exclusiveMaximum") <= 3.0 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end