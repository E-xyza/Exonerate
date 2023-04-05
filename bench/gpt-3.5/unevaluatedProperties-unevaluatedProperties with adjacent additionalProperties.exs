defmodule :"unevaluatedProperties with adjacent additionalProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, :foo) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
