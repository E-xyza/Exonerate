defmodule :"float and integers are equal up to 64-bit representation limits-gpt-3.5" do
  def validate(const) when is_integer(const) and const == 9_007_199_254_740_992 do
    :ok
  end

  def validate(const) when is_float(const) and const == 9_007_199_254_740_992.0 do
    :ok
  end

  def validate(_) do
    :error
  end
end