defmodule :"anyOf-anyOf with one empty schema-gpt-3.5" do
  def validate(num) when is_number(num) do
    :ok
  end

  def validate(_) do
    :error
  end
end