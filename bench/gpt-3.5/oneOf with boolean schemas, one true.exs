defmodule :"oneOf with boolean schemas, one true-gpt-3.5" do
  def validate(value) do
    case value do
      true, false, false -> :ok
      _ -> :error
    end
  end
end
