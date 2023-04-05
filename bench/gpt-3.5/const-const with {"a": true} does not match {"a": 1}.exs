defmodule :"const with {\"a\": true} does not match {\"a\": 1}-gpt-3.5" do
  def validate(object) when is_map(object) and object == %{"a" => true} do
    :ok
  end

  def validate(_) do
    :error
  end
end