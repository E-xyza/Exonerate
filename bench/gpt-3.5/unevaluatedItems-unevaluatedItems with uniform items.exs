defmodule :"unevaluatedItems-unevaluatedItems with uniform items-gpt-3.5" do
  def validate(arr) when is_list(arr) do
    case Enum.all?(arr, fn x -> is_binary(x) end) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end