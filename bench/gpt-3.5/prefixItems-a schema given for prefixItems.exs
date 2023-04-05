defmodule :"prefixItems-a schema given for prefixItems-gpt-3.5" do
  def validate(%{"prefixItems" => [%{"type" => "integer"}, %{"type" => "string"}]} = object) do
    case {Map.get(object, 0), Map.get(object, 1)} do
      {nil, _} -> {:error, "First element is missing"}
      {_, nil} -> {:error, "Second element is missing"}
      {int, str} when is_integer(int) and is_binary(str) -> :ok
      {int, str} -> {:error, "First element is not an integer or second element is not a string"}
    end
  end

  def validate(_) do
    {:error, "Invalid object"}
  end
end
