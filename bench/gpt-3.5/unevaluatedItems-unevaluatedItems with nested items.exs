defmodule :"unevaluatedItems with nested items-gpt-3.5" do
  def validate(array) when is_list(array) and Enum.all?(array, &is_binary/1) do
    :ok
  end

  def validate(_) do
    :error
  end
end