defmodule :"prefixItems-prefixItems with boolean schemas-gpt-3.5" do
  def validate(json) when is_map(json) do
    case json["prefixItems"] do
      [true, false] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end