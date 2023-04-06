defmodule :"type-boolean type matches booleans-gpt-3.5" do
  def validate(object) when is_boolean(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end