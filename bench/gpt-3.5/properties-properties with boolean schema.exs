defmodule :"properties-properties with boolean schema-gpt-3.5" do
  def validate(%{"foo" => true, "bar" => false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end