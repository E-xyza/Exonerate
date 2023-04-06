defmodule :"maxItems-maxLength validation" do
  def validate(list) when is_list(list) and length(list) <= 2, do: :ok
  def validate(_), do: :error
end
