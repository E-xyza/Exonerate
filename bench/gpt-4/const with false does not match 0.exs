defmodule :"const with false does not match 0" do
  def validate(false), do: :ok
  def validate(_), do: :error
end
