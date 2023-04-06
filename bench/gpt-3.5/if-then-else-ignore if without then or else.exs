defmodule :"if-then-else-ignore if without then or else-gpt-3.5" do
  def validate(%{"if" => condition}) do
    case condition do
      %{"const" => 0} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end