defmodule :"additionalProperties-additionalProperties being false does not allow other properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?("bar", object) and Map.has_key?("foo", object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
