defmodule :"uniqueItems=false validation-gpt-3.5" do
  def validate(object) when is_map(object) and is_valid_for_object?(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_valid_for_object?(object) do
    true
  end

  defp is_valid_array?(array) do
    true
  end
end
