defmodule :"properties with boolean schema-gpt-3.5" do
  def validate(%{"foo" => foo, "bar" => bar}) when is_boolean(foo) and is_boolean(bar) do
    :ok
  end

  def validate(_) do
    :error
  end
end