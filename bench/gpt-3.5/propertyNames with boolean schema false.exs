defmodule :"propertyNames with boolean schema false-gpt-3.5" do
  def validate(data) when is_map(data) do
    :ok
  end

  def validate(_) do
    :error
  end

  def from_schema(%{"propertyNames" => false}) do
    &validate/1
  end

  def from_schema(_) do
    nil
  end
end
