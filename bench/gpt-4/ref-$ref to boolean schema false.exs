defmodule :"ref-$ref to boolean schema false" do
  def validate(false), do: :ok
  def validate(_), do: {:error, "Invalid value"}
end
