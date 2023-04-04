defmodule :"unevaluatedItems with $ref" do
  def validate([first | rest]) when is_list(rest) and is_binary(first) do
    case rest do
      [true | _] -> :ok
      _ -> :error
    end
  end
  def validate(_), do: :error
end
