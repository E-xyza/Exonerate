defmodule :"minimum validation" do
  def validate(number) when is_number(number) and number >= 1.1, do: :ok
  def validate(_), do: :error
end
