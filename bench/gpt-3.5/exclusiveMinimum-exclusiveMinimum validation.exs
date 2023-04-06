defmodule :"exclusiveMinimum-exclusiveMinimum validation-gpt-3.5" do
  def validate(value) do
    case value do
      x when is_number(x) and x > 1.1 -> :ok
      _ -> :error
    end
  end
end