defmodule :"const-const with {\"a\": true} does not match {\"a\": 1}-gpt-3.5" do
  def validate(map) when is_map(map) and map == %{"a" => true} do
    :ok
  end

  def validate(_) do
    :error
  end
end