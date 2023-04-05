defmodule :"unevaluatedItems-unevaluatedItems with tuple" do
  def validate([first | rest]) when is_list(rest) do
    if is_binary(first) and Enum.empty?(rest) do
      :ok
    else
      :error
    end
  end
  def validate([]), do: :error
  def validate(_), do: :error
end
