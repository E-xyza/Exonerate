defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent additionalProperties" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> true
      end

    if foo_valid, do: :ok, else: :error
  end

  def validate(_), do: :error
end
