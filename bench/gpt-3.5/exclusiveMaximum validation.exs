defmodule :"exclusiveMaximum validation-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate(value) do
    case value do
      num when is_number(num) and num <= 3.0 -> :ok
      _ -> :error
    end
  end
end
