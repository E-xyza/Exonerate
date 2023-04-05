defmodule :"allOf with boolean schemas, all false-gpt-3.5" do
  def validate(object) when is_map(object) do
    :error
  end

  def validate(_) do
    :ok
  end
end