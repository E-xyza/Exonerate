defmodule :"unevaluatedItems-unevaluatedItems with if/then/else-gpt-3.5" do
  def validate(decoded_value) do
    case decoded_value do
      %{
        type: "array",
        unevaluatedItems: false,
        prefixItems: prefix_items,
        if: if_clause,
        then: then_clause,
        else: else_clause
      }
      when length(prefix_items) == 1 and length(if_clause.prefixItems) == 2 and
             length(else_clause.prefixItems) == 4 and length(then_clause.prefixItems) == 3 ->
        if validate_prefix_items(prefix_items) and validate_if_clause(if_clause.prefixItems) and
             validate_else_clause(else_clause.prefixItems) and
             validate_then_clause(then_clause.prefixItems) do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end

  defp validate_prefix_items([%{const: "foo"}]) do
    true
  end

  defp validate_prefix_items(_) do
    false
  end

  defp validate_if_clause([true, %{const: "bar"}]) do
    true
  end

  defp validate_if_clause(_) do
    false
  end

  defp validate_else_clause([true, true, true, %{const: "else"}]) do
    true
  end

  defp validate_else_clause(_) do
    false
  end

  defp validate_then_clause([true, true, %{const: "then"}]) do
    true
  end

  defp validate_then_clause(_) do
    false
  end
end