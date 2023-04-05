defmodule :"uniqueItems=false validation-gpt-3.5" do
  def validate(object) when is_list(object) do
    validate_list(object, [])
  end

  def validate(_) do
    :ok
  end

  defp validate_list([], _) do
    :ok
  end

  defp validate_list([head | tail], previous_items) when head in previous_items do
    :error
  end

  defp validate_list([head | tail], previous_items) do
    validate_list(
      tail,
      [head | previous_items]
    )
  end
end