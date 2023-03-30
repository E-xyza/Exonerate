defmodule :"float and integers are equal up to 64-bit representation limits" do
  def validate(9007199254740992), do: :ok
  def validate(_), do: :error
end
