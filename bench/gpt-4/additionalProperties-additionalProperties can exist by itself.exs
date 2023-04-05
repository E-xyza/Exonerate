defmodule :"additionalProperties-additionalProperties can exist by itself" do
  def validate(object) when is_map(object) do
    values = Map.values(object)

    valid? = Enum.all?(values, &is_boolean/1)

    if valid?, do: :ok, else: :error
  end

  def validate(_), do: :error

  defp is_boolean(value), do: value in [true, false]
end
