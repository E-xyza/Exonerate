defmodule :"multipleOf-invalid instance should not raise error when float division = inf-gpt-3.5" do
  def validate(object)
      when is_integer(object) and
             rem(
               object,
               0.123456789
             ) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end