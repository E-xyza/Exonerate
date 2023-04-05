defmodule :"type-boolean type matches booleans-gpt-3.5" do
  def validate(value) do
    case value do
      true, false -> :ok
      _ -> :error
    end
  end
end
