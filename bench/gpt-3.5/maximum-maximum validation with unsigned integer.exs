defmodule :"maximum-maximum validation with unsigned integer-gpt-3.5" do
  def validate(value) do
    case value do
      %{"maximum" => maximum} when is_integer(maximum) and maximum >= 0 -> :ok
      _ -> :error
    end
  end
end