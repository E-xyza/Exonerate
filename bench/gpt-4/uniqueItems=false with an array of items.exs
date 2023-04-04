defmodule :"uniqueItems=false with an array of items" do
  def validate([first, second | _rest]) do
    if is_boolean(first) and is_boolean(second) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
