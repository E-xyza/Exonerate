defmodule :"unevaluatedProperties with nested patternProperties-gpt-3.5" do
  @spec validate(term) :: atom
  def validate(decoded_json) when is_map(decoded_json) do
    case validate_object(decoded_json) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "foo") do
      true ->
        Map.get(
          object,
          "foo"
        )
        |> validate_string()

      false ->
        true
    end &&
      case Map.has_key?(object, "bar") do
        true ->
          Map.keys(object)
          |> Enum.filter(&String.match?(&1, ~r/^bar/))
          |> Enum.reduce(
            true,
            fn key, acc -> Map.get(object, key) |> validate_string() && acc end
          )

        false ->
          true
      end
  end

  defp validate_string(string) do
    String.valid?(string)
  end
end
