defmodule :"unevaluatedItems-unevaluatedItems with tuple-gpt-3.5" do
  def validate(data) when is_list(data) do
    case Enum.all?(data, fn item -> is_binary(item) end) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end