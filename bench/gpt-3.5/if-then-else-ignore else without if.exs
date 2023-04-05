defmodule :"if-then-else-ignore else without if-gpt-3.5" do
  def validate(%{"else" => %{"const" => 0}} = json) do
    case json do
      %{"else" => %{"const" => 0}} -> :ok
      _ -> :error
    end
  end
end
