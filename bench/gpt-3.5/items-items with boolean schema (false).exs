defmodule :"items-items with boolean schema (false)-gpt-3.5" do
  def validate(object) when is_map(object) and map_size(object) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end