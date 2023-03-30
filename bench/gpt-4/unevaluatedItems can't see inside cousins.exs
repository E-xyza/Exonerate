defmodule :"unevaluatedItems can't see inside cousins" do
  def validate([true | rest]) when is_list(rest) do
    if Enum.all?(rest, fn item -> is_boolean(item) or is_binary(item) or is_number(item) end) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
