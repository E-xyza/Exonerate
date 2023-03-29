defmodule :"array type matches arrays-gpt-3.5" do
  def validate(data) when is_list(data) do
    :ok
  end

  def validate(_) do
    :error
  end
end
