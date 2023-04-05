defmodule :"if-then-else-validate against correct branch, then vs else" do
  def validate(value) when is_number(value) do
    if value < 0 do
      if value > -10 do
        :error
      else
        :ok
      end
    else
      if rem(value, 2) == 0 do
        :ok
      else
        :error
      end
    end
  end

  def validate(_), do: :error
end
