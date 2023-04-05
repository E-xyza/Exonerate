defmodule :"oneOf with empty schema-gpt-3.5" do
  def validate(object) when is_number(object) do
    :ok
  end

  def validate(object) when is_map(object) do
    :error
  end

  def validate(_) do
    :error
  end
end