defmodule :"oneOf-oneOf with boolean schemas, more than one true-gpt-3.5" do
  def validate(json) do
    case json do
      true, false -> :ok
      [true, true, false] -> :ok
      _ -> :error
    end
  end
end
