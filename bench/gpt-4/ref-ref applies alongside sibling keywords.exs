defmodule :"ref applies alongside sibling keywords" do
  def validate(%{"foo" => value}) when is_list(value) and length(value) <= 2, do: :ok
  def validate(_), do: :error
end
