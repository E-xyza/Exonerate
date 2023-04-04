defmodule :"unevaluatedItems with if/then/else" do
  def validate(value) when is_list(value) and valid_if_then_else(value) do
    :ok
  end
  def validate(_), do: :error

  defp valid_if_then_else(["foo", "bar" | rest]) do
    case rest do
      ["then"] -> true
      _ -> false
    end
  end
  defp valid_if_then_else(["foo" | rest]) do
    case rest do
      [_, _, "else"] -> true
      _ -> false
    end
  end
  defp valid_if_then_else(_), do: false
end
