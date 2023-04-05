defmodule :"uniqueItems=false validation" do
  def validate(list) when is_list(list), do: :ok
  def validate(_), do: :error
end
