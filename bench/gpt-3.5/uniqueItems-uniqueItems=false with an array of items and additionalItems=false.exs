defmodule :"uniqueItems-uniqueItems=false with an array of items and additionalItems=false-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(object) when is_list(object) and not contains_duplicates(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp contains_duplicates(items) do
    Enum.count_duplicates(items) > 0
  end
end