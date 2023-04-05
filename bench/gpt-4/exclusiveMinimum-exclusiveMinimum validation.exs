defmodule :"exclusiveMinimum-exclusiveMinimum validation" do
  def validate(number) when is_number(number) do
    if number > 1.1, do: :ok, else: :error
  end

  def validate(_), do: :error
end
