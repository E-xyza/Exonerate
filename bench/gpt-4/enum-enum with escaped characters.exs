defmodule :"enum with escaped characters" do
  def validate("foo\nbar"), do: :ok
  def validate("foo\rbar"), do: :ok
  def validate(_), do: :error
end
