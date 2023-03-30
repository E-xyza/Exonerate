defmodule :"unevaluatedItems with boolean schemas" do
  def validate(value) when is_list(value) do
    :ok
  end
  def validate(_), do: :error
end
