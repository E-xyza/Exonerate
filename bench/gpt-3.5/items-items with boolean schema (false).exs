defmodule :"items-items with boolean schema (false)-gpt-3.5" do
  def validate(schema)

  def validate(%{"items" => false}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
