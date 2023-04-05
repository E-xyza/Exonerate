defmodule :"simple enum validation-gpt-3.5" do
  def validate(object) when is_integer(object) and object in [1, 2, 3] do
    :ok
  end

  def validate(_) do
    :error
  end
end
