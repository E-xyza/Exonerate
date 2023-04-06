defmodule :"propertyNames-propertyNames validation-gpt-3.5" do
  def validate(map) when is_map(map) and map_size(map) <= 3 do
    :ok
  end

  def validate(_) do
    :error
  end
end