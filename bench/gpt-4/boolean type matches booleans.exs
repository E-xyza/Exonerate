defmodule :"boolean type matches booleans" do
  def validate(value) when is_boolean(value), do: :ok
  def validate(_), do: :error
end
