defmodule :"if and then without else" do
  def validate(value) when is_number(value) do
    if value < 0 do
      if value >= -10 do
        :ok
      else
        :error
      end
    else
      :ok
    end
  end

  def validate(_), do: :error
end
