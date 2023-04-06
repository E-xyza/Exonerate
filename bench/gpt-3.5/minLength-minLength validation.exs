defmodule :"minLength-minLength validation-gpt-3.5" do
  def validate(value) do
    case value do
      String.t() when String.length(value) >= 2 -> :ok
      _ -> :error
    end
  end
end