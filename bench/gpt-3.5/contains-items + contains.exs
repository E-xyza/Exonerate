defmodule :"items + contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_contains(object) do
      :ok -> validate_items(Map.get(object, "items", []))
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_contains(object) do
    case Map.get(object, "contains", nil) do
      nil ->
        :ok

      contains ->
        multiples_of = Enum.filter(object[:multiple_of], &is_integer/1)

        case contains do
          %{"multipleOf" => multiple_of} when is_integer(multiple_of) ->
            validate_multiple_of(multiples_of, multiple_of)

          _ ->
            :error
        end
    end
  end

  defp validate_items([]) do
    :ok
  end

  defp validate_items(items) do
    multiples_of = Enum.filter(items[:multiple_of], &is_integer/1)

    case items do
      %{"multipleOf" => multiple_of} when is_integer(multiple_of) ->
        validate_multiple_of(multiples_of, multiple_of)

      _ ->
        :error
    end
  end

  defp validate_multiple_of(multiples_of, factor) do
    if Enum.all?(multiples_of, fn n -> rem(n, factor) == 0 end) do
      :ok
    else
      :error
    end
  end
end