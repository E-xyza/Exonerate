defmodule :"items with boolean schema (false)-gpt-3.5" do
  def validate(object)
      when is_map(object) and map_size(object) == 1 and map.get(object, "items") == false do
    :ok
  end

  def validate(_) do
    :error
  end
end