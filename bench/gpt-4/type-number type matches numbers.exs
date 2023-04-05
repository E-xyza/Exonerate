defmodule :"number type matches numbers" do
  def validate(value) when is_number(value), do: :ok
  def validate(_), do: :error
end
