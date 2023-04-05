defmodule :"if with boolean schema true" do
  def validate("then"), do: :ok
  def validate("else"), do: :error
  def validate(_), do: :error
end
