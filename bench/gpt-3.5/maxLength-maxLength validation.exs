defmodule :"maxLength validation-gpt-3.5" do
  def validate(str) when is_binary(str) do
    case String.length(str) <= 2 do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end