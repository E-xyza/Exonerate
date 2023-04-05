defmodule :"allOf with the first empty schema-gpt-3.5" do
  def validate(object) when is_number(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end