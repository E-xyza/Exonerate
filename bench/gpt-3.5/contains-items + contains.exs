defmodule :"contains-items + contains-gpt-3.5" do
  def validate(object)
      when is_list(object) and Enum.any?(object, fn x -> rem(x, 3) == 0 end) and
             Enum.all?(object, fn x -> rem(x, 2) == 0 end) do
    :ok
  end

  def validate(_) do
    :error
  end
end