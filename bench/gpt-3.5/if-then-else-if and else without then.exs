defmodule :"if-then-else-if and else without then-gpt-3.5" do
  def validate(object) when is_map(object) do
    if_else(object, %{"else" => %{"multipleOf" => 2}, "if" => %{"exclusiveMaximum" => 0}})
  end

  def validate(_) do
    :error
  end

  defp if_else(object, %{"if" => if_clause, "else" => else_clause}) do
    if validate_clause(if_clause, object) == :ok do
      :ok
    else
      validate_clause(else_clause, object)
    end
  end

  defp if_else(_, _) do
    :error
  end

  defp validate_clause(%{"multipleOf" => divisor}, number) when is_integer(number) do
    if rem(number, divisor) == 0 do
      :ok
    else
      :error
    end
  end

  defp validate_clause(%{"exclusiveMaximum" => limit}, number) when is_number(number) do
    if number < limit do
      :ok
    else
      :error
    end
  end

  defp validate_clause(_, _) do
    :error
  end
end