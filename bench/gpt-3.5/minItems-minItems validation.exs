defmodule :"minItems-minItems validation-gpt-3.5" do
  def validate(array) when is_list(array) and length(array) >= 1 do
    :ok
  end

  def validate(_) do
    :error
  end
end