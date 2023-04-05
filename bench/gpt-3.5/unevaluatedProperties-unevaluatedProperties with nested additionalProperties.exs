defmodule :"unevaluatedProperties-unevaluatedProperties with nested additionalProperties-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "foo") and is_binary(Map.get(object, "foo")) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
