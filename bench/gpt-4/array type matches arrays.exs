defmodule :"array type matches arrays" do
  def validate(value) when is_list(value), do: :ok
  def validate(_), do: :error
end
