defmodule :"ignore if without then or else-gpt-3.5" do
  def validate(json) when json == %{"if" => %{"const" => 0}} do
    :ok
  end

  def validate(_) do
    :error
  end
end