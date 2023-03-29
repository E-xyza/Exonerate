defmodule :"if and else without then-gpt-3.5" do
  def validate(object) when is_map(object) and validate_object(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.get(object, "else") do
      nil -> true
      _else_value -> multiple_of(object)
    end and
      case Map.get(object, "if") do
        nil -> true
        _if_value -> exclusive_maximum(object)
      end
  end

  defp multiple_of(object) do
    case Map.get(object, "else") do
      {_key, multiple_of} when is_integer(multiple_of) ->
        rem(
          multiple_of,
          2
        ) == 0

      _ ->
        true
    end
  end

  defp exclusive_maximum(object) do
    case Map.get(object, "if") do
      {_key, exclusive_maximum} when is_number(exclusive_maximum) -> exclusive_maximum > 0
      _ -> true
    end
  end
end
