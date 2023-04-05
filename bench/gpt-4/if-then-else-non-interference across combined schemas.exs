defmodule :"if-then-else-non-interference across combined schemas" do
  def validate(value) when is_number(value) do
    exclusive_max = value < 0
    min_check = value >= -10
    multiple_of_2 = rem(value, 2) == 0

    cond do
      exclusive_max and min_check ->
        :ok

      not exclusive_max and multiple_of_2 ->
        :ok

      true ->
        :error
    end
  end

  def validate(_), do: :error
end
