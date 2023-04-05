defmodule :"array type matches arrays-gpt-3.5" do
  def validate(array) when is_list(array) do
    :ok
  end

  def validate(_) do
    :error
  end
end