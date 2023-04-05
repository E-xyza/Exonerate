defmodule :"cousin unevaluatedProperties, true and false, true with properties-gpt-3.5" do
  def validate(json) when is_map(json) do
    if validate_object(json) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{}) do
    true
  end

  defp validate_object(_) do
    false
  end
end
