defmodule :"minimum validation with signed integer-gpt-3.5" do
  def validate(value) when is_integer(value) and value >= -2 do
    :ok
  end

  def validate(_) do
    :error
  end
end