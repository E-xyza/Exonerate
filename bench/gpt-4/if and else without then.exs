defmodule :"if and else without then" do
  def validate(value) when is_number(value) do
    if value < 0 do
      :ok
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
