defmodule :"unevaluatedItems false-gpt-3.5" do
  def validate([]) do
    :ok
  end

  def validate([_ | _]) do
    :error
  end
end