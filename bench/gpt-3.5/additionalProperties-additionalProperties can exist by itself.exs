defmodule :"additionalProperties can exist by itself-gpt-3.5" do
  def validate(value) when is_map(value) do
    validate_object(value)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{} = object) do
    if Map.keys(object) -- [:additionalProperties] == [] do
      :ok
    else
      :error
    end
  end

  defp validate_object(_) do
    :error
  end
end