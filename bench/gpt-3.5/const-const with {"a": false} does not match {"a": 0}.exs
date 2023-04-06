defmodule :"const-const with {\"a\": false} does not match {\"a\": 0}-gpt-3.5" do
  def validate(object) when is_map(object) and object == %{"a" => false} do
    :ok
  end

  def validate(_) do
    :error
  end
end