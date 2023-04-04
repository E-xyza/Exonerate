defmodule :"$ref to boolean schema true" do
  def validate(true), do: :ok
  def validate(_), do: {:error, "Invalid value"}
end
