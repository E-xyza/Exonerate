defmodule :"unevaluatedItems with anyOf" do
  def validate(value) when is_list(value) and length(value) in [2, 3] and valid_anyof(value) do
    :ok
  end
  def validate(_), do: :error

  defp valid_anyof(["foo" | rest]) do
    case rest do
      [_, "bar"] -> true
      [_, _, "baz"] -> true
      _ -> false
    end
  end
  defp valid_anyof(_), do: false
end
