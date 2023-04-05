defmodule :"type-number type matches numbers-gpt-3.5" do
  def validate(json) when is_integer(json) do
    :ok
  end

  def validate(_) do
    :error
  end
end
