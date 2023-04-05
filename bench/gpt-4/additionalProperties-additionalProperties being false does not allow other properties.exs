defmodule :"additionalProperties being false does not allow other properties" do
  def validate(value) do
    case value do
      %{"foo" => _, "bar" => _} = object ->
        keys = Map.keys(object)

        if Enum.all?(keys, &match_property_pattern?/1) do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end

  defp match_property_pattern?(key) do
    key in ["foo", "bar"] or Regex.match?(~r/^v/, key)
  end
end
