defmodule :"const-const with array-gpt-3.5" do
  def validate(object) when is_map(object) and object == %{"foo" => "bar"} do
    :ok
  end

  def validate(_) do
    :error
  end
end