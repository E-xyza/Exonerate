defmodule :"nested items-gpt-3.5" do
  def validate([_ | _] = object) when is_list(object) do
    items_array(object)
  end

  def validate(_) do
    :error
  end

  defp items_array([_ | _] = array) when is_list(array) do
    recursive_items(array)
  end

  defp items_array(_) do
    :error
  end

  defp recursive_items([item | rest] = array) do
    recursive_items(rest, item)
  end

  defp recursive_items([], _) do
    :ok
  end

  defp recursive_items(_, item) when is_list(item) do
    items_array(item)
  end

  defp recursive_items(_, item) do
    item_type(item)
  end

  defp item_type([_ | _] = array) do
    items_array(array)
  end

  defp item_type(item) when is_number(item) do
    :ok
  end

  defp item_type(_) do
    :error
  end
end