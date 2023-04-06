defmodule :"not-not with boolean schema false-gpt-3.5" do
  def validate(object) when object == false do
    :ok
  end

  def validate(_) do
    :error
  end
end