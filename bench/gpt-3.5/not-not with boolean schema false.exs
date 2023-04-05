defmodule :"not with boolean schema false-gpt-3.5" do
  def validate(%{"not" => false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end