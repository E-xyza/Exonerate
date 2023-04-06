defmodule :"maxLength-maxLength validation-gpt-3.5" do
  def validate(object) when is_binary(object) and byte_size(object) <= 2 do
    :ok
  end

  def validate(_) do
    :error
  end
end