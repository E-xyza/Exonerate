defmodule :"type-type: array or object-gpt-3.5" do
  def validate(object) when is_map(object) or is_list(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end