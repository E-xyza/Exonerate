defmodule :"if-then-else-ignore else without if-gpt-3.5" do
  def validate(%{"else" => %{"const" => 0}} = _) do
    :ok
  end

  def validate(_) do
    :error
  end
end