defmodule :"enum with true does not match 1-gpt-3.5" do
  def validate({:array, elements}) when elements == [true] do
    :ok
  end

  def validate(_) do
    :error
  end
end