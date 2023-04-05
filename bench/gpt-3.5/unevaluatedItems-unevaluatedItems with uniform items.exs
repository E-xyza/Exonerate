defmodule :"unevaluatedItems with uniform items-gpt-3.5" do
  def validate(%{"type" => "object"} = object) when is_map(object) do
    :ok
  end

  def validate(%{"type" => "array", "items" => %{"type" => "string"}} = array)
      when is_list(array) do
    :ok
  end

  def validate(_) do
    :error
  end
end