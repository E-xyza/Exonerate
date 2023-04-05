defmodule :"unevaluatedItems-unevaluatedItems with oneOf" do
  def validate(value) when is_list(value) and length(value) == 3 and valid_oneof(value) do
    :ok
  end
  def validate(_), do: :error

  defp valid_oneof(["foo" | rest]) do
    case rest do
      [_, "bar"] -> true
      [_, "baz"] -> true
      _ -> false
    end
  end
  defp valid_oneof(_), do: false
end
