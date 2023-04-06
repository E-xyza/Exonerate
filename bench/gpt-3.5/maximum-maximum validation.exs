defmodule :"maximum-maximum validation-gpt-3.5" do
  def validate(number) do
    validate(number, %{"maximum" => 3.0})
  end

  def validate(number, %{"maximum" => maximum}) when is_number(number) do
    if number <= maximum do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end