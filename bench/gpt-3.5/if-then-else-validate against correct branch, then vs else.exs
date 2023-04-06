defmodule :"if-then-else-validate against correct branch, then vs else-gpt-3.5" do
  def validate(schema) when is_map(schema) do
    if_clause = schema[:if] || %{}
    else_clause = schema[:else] || %{}
    then_clause = schema[:then] || %{}

    if validate_clause(if_clause, "exclusiveMaximum", fn val -> val <= 0 end) == :ok do
      cond do
        validate_clause(then_clause, "minimum", &(&1 >= -10)) == :ok -> :ok
        validate_clause(else_clause, "multipleOf", fn val -> rem(val, 2) == 0 end) == :ok -> :ok
        true -> :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_clause(clause, keyword, validation_fn) when is_map(clause) do
    case clause[keyword] do
      nil -> :ok
      val when validation_fn.(val) -> :ok
      _ -> :error
    end
  end

  defp validate_clause(_, _, _) do
    :ok
  end
end