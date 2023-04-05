defmodule :oneOf do
  def validate(object) when is_integer(object), do: :ok
  def validate(object) when is_map(object) and object["minimum"] >= 2, do: :ok
  def validate(_), do: :error
end
