defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent patternProperties" do
  import Regex

  def validate(object) when is_map(object) do
    pattern = ~r/^foo/

    all_valid =
      Enum.all?(object, fn {key, value} ->
        case Regex.match?(pattern, key) do
          true -> is_binary(value)
          false -> false
        end
      end)

    if all_valid, do: :ok, else: :error
  end

  def validate(_), do: :error
end
