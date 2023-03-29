defmodule :"maxProperties = 0 means the object is empty-gpt-3.5" do
  def validate(object) when is_map(object) and map_size(object) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end
