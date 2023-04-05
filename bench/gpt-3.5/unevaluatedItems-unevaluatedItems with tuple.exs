defmodule :"unevaluatedItems with tuple-gpt-3.5" do
  def validate(object) when is_list(object) do
    case Enum.all?(object, fn item -> is_binary(item) end) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end