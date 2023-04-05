defmodule :"not-not more complex schema" do
  def validate(object) when is_map(object) and is_nil(object["foo"]), do: :ok
  def validate(_), do: :error
end
