defmodule :"properties-properties with escaped characters" do
  def validate(object) when is_map(object) do
    properties_valid? = validate_properties(object)

    if properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_properties(object) do
    properties = [
      {"foo\tbar", &is_number/1},
      {"foo\nbar", &is_number/1},
      {"foo\fbar", &is_number/1},
      {"foo\rbar", &is_number/1},
      {"foo\"bar", &is_number/1},
      {"foo\\bar", &is_number/1}
    ]

    Enum.all?(properties, fn {key, validator} ->
      case Map.get(object, key) do
        nil -> true
        value -> validator.(value)
      end
    end)
  end
end
