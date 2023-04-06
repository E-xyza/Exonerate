defmodule :"type-string type matches strings-gpt-3.5" do
  def validate(string) when is_binary(string) do
    :ok
  end

  def validate(_) do
    :error
  end
end