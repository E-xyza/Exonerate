defmodule :"additionalProperties-additionalProperties should not look in applicators-gpt-3.5" do
  def validate(object) when is_map(object) and Map.keys(object) == ["foo"] do
    :ok
  end

  def validate(_) do
    :error
  end
end