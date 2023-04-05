defmodule :"unevaluatedProperties-unevaluatedProperties with nested unevaluatedProperties-gpt-3.5" do
  @spec validate(map) :: :ok | :error
  def validate(data) when is_map(data) do
    if validate_properties(data) and validate_unevaluated_properties(data) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(data) do
    case Map.has_key?(data, "foo") do
      true ->
        case validate_type(Map.get(data, "foo"), "string") do
          true -> true
          false -> false
        end

      false ->
        true
    end
  end

  defp validate_type(value, "string") do
    is_binary(value)
  end

  defp validate_type(_, _) do
    false
  end

  defp validate_unevaluated_properties(data) do
    case Map.keys(data) |> length() do
      n when n > 2 -> false
      _ -> true
    end
  end
end
