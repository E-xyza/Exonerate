defmodule :"allOf-allOf with the last empty schema-gpt-3.5" do
  def validate(value) when is_number(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end