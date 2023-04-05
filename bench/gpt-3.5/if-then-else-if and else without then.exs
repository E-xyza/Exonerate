defmodule :"if and else without then-gpt-3.5" do
  def validate(object) when is_map(object) and Keyword.get(object, :if, nil) do
    if validate_clause(Keyword.get(object, :if), object) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_clause(clause, object) do
    case Keyword.get(clause, :exclusiveMaximum, nil) do
      nil ->
        true

      exclusive_maximum ->
        if object <= exclusive_maximum do
          false
        else
          true
        end
    end
  end

  defp validate_clause(clause, object) do
    case Keyword.get(clause, :multipleOf, nil) do
      nil -> true
      multiple_of -> rem(object, multiple_of) == 0
    end
  end
end