defmodule :"maxProperties-maxProperties validation-gpt-3.5" do
  def validate(object) when is_map(object) and map_size(object) <= 2 do
    :ok
  end

  def validate(_) do
    :error
  end
end