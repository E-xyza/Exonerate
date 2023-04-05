defmodule :"string type matches strings" do
  def validate(value) when is_binary(value), do: :ok
  def validate(_), do: :error
end
