defmodule :"additionalProperties-additionalProperties are allowed by default" do
  def validate(object) when is_map(object) do
    keys = Map.keys(object)

    valid? = Enum.all?(keys, &is_property_valid?/1)

    if valid?, do: :ok, else: :error
  end

  def validate(_), do: :error

  defp is_property_valid?(key) do
    allowed_properties = ["bar", "foo"]
    key in allowed_properties
  end
end
