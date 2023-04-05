defmodule :"non-ASCII pattern with additionalProperties-gpt-3.5" do
  def validate(map) when is_map(map) do
    if Regex.match?(~r/^á/, Map.keys(map)) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end