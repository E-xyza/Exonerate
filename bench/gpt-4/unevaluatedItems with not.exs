defmodule :"unevaluatedItems with not" do
  def validate(value) when is_list(value) and length(value) == 3 and valid_not(value) do
    :ok
  end
  def validate(_), do: :error

  defp valid_not(["foo" | rest]) do
    case rest do
      [_, "bar"] -> true
      _ -> false
    end
  end
  defp valid_not(_), do: false
end
