defmodule :"type-null type matches only the null object" do
  def validate(value) when is_nil(value), do: :ok
  def validate(_), do: :error
end
