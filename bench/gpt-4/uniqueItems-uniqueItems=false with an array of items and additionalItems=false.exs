defmodule :"uniqueItems-uniqueItems=false with an array of items and additionalItems=false" do
  def validate([first, second]) do
    if is_boolean(first) and is_boolean(second) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
