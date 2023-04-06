defmodule :"ref-relative pointer ref to object" do
  def validate(map) when is_map(map) do
    keys = Map.keys(map)

    cond do
      keys -- ["foo", "bar"] != [] ->
        :error

      keys -- ["foo"] == [] and not is_integer(map["foo"]) ->
        :error

      keys -- ["bar"] == [] and not validate_foo(map["bar"]) ->
        :error

      true ->
        :ok
    end
  end

  def validate(_), do: :error

  defp validate_foo(value) do
    is_integer(value)
  end
end
