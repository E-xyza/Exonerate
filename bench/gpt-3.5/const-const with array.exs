defmodule :"const with array-gpt-3.5" do
  def validate(%{"const" => [const]}) when is_map(const) do
    :ok
  end

  def validate(_) do
    :error
  end
end
