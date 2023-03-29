defmodule :"if with boolean schema true-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{} = object) do
    if validate_if_clause(object) do
      validate_then_clause(object)
    else
      :error
    end
  end

  defp validate_object(_) do
    :error
  end

  defp validate_if_clause(object) do
    case Map.get(object, "if") do
      true -> true
      _ -> false
    end
  end

  defp validate_then_clause(object) do
    case Map.get(object, "then") do
      %{"const" => "then"} -> :ok
      _ -> :error
    end
  end
end
