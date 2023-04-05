defmodule :"validation of string-encoded content based on media type-gpt-3.5" do
  def validate(json) when is_map(json) do
    {:ok, _} = Jason.decode(json)
    :ok
  end

  def validate(_) do
    :error
  end
end