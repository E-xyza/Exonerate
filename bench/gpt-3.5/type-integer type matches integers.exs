defmodule :"integer type matches integers-gpt-3.5" do
  def validate(object) when is_integer(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end