defmodule :"allOf simple types" do
  def validate(number) when is_number(number) do
    if number >= 20 and number <= 30 do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
