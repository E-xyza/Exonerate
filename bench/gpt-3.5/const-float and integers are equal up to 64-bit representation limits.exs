defmodule :"const-float and integers are equal up to 64-bit representation limits-gpt-3.5" do
  def validate(const) do
    case const do
      %{"const" => 9_007_199_254_740_992} -> :ok
      _ -> :error
    end
  end
end