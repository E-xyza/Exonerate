defmodule :"ref-relative pointer ref to array-gpt-3.5" do
  def validate(%{"prefixItems" => prefix_items}) do
    case prefix_items do
      [%{"type" => "integer"}, %{"$ref" => "#/prefixItems/0"}] -> :ok
      _ -> :error
    end
  end
end