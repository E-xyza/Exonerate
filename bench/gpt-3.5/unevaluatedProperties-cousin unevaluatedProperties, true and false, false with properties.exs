defmodule :"cousin unevaluatedProperties, true and false, false with properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "foo") do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end