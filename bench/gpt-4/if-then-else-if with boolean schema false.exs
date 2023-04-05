defmodule :"if with boolean schema false" do
  def validate("else"), do: :ok
  def validate("then"), do: :error
  def validate(_), do: :error
end
