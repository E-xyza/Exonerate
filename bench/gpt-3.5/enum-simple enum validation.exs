defmodule :"simple enum validation-gpt-3.5" do
  def validate(json) when is_integer(json) and json in [1, 2, 3] do
    :ok
  end

  def validate(_) do
    :error
  end
end