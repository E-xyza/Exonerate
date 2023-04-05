defmodule :"not with boolean schema true-gpt-3.5" do
  def validate(bool) when is_boolean(bool) and bool == false do
    :ok
  end

  def validate(_) do
    :error
  end
end