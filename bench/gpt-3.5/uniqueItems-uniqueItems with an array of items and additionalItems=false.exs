defmodule :"uniqueItems with an array of items and additionalItems=false-gpt-3.5" do
  def validate(array) when is_list(array) and Enum.all?(array, &is_boolean/1) do
    :ok
  end

  def validate(_) do
    :error
  end
end