defmodule :"items-a schema given for items-gpt-3.5" do
  def validate(%{"items" => %{"type" => "integer"}} = object) do
    if is_list(object) and Enum.all?(object, fn n -> is_integer(n) end) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end