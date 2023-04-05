defmodule :"allOf-allOf with boolean schemas, all true-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(%{allOf: conditions}) when is_list(conditions) do
    if conditions |> Enum.all?(&is_boolean/1) do
      :ok
    else
      :error
    end
  end

  defp validate_map(_) do
    :error
  end
end
