defmodule :"nested unevaluatedProperties, outer false, inner true, properties outside-gpt-3.5" do
  def validate(object) when is_map(object) do
    properties = %{"foo" => &is_binary/1}
    required = ["foo"]

    valid_props =
      Map.keys(properties)
      |> Enum.all?(fn prop ->
        prop in required or
          (Map.has_key?(object, prop) and properties[prop].(Map.get(object, prop)))
      end)

    if valid_props do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
