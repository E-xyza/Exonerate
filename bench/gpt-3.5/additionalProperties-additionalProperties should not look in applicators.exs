defmodule :"additionalProperties-additionalProperties should not look in applicators-gpt-3.5" do
  def validate(object) when is_map(object) and not Map.keys(object) -- [:foo] == MapSet.new() do
    :ok
  end

  def validate(_) do
    :error
  end
end
