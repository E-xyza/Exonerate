defmodule :"infinite-loop-detection-evaluating the same schema location against the same data location twice is not a sign of an infinite loop" do
  def validate(object) when is_map(object) do
    all_integer_properties = Enum.all?(object, fn {_key, value} -> is_integer(value) end)

    if all_integer_properties and Map.has_key?(object, "foo") do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
