defmodule :"object type matches objects" do
  def validate(value) when is_map(value), do: :ok
  def validate(_), do: :error
end
