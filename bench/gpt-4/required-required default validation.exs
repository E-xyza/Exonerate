defmodule :"required default validation" do
  def validate(object) when is_map(object), do: :ok
  def validate(_), do: :error
end
