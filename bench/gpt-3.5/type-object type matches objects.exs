defmodule :"type-object type matches objects-gpt-3.5" do
  def validate(item) when is_map(item) do
    :ok
  end

  def validate(_) do
    :error
  end
end
