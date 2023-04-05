defmodule :"enum with 1 does not match true-gpt-3.5" do
  def validate(object) when is_map(object) and object["enum"] == [1] do
    :ok
  end

  def validate(_) do
    :error
  end
end