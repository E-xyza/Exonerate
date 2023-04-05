defmodule :"prefixItems with boolean schemas-gpt-3.5" do
  def validate(%{"prefixItems" => prefix_items}) when is_list(prefix_items) do
    case prefix_items do
      [true | false | _rest] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end