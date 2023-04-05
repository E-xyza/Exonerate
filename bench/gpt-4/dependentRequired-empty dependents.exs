defmodule :"empty dependents" do
  def validate(object) when is_map(object) and not Map.has_key?(object, :bar), do: :ok
  def validate(_), do: :error
end
