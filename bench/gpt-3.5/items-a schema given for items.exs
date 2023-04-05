defmodule :"a schema given for items-gpt-3.5" do
  def validate(object) when is_map(object) and is_integer(object["items"]) do
    :ok
  end

  def validate(_) do
    :error
  end
end