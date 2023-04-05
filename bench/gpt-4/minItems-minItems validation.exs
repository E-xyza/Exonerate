defmodule :"minItems validation" do
  def validate(list) when is_list(list) and length(list) >= 1, do: :ok
  def validate(_), do: :error
end
