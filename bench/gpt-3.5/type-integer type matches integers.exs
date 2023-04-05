defmodule :"type-integer type matches integers-gpt-3.5" do
  def validate(n) when is_integer(n) do
    :ok
  end

  def validate(_) do
    :error
  end
end
