defmodule :"allOf-allOf with one empty schema-gpt-3.5" do
  def validate(data) when is_map(data) do
    :ok
  end

  def validate(_) do
    :error
  end
end