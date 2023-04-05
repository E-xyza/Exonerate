defmodule :"oneOf-oneOf with missing optional property" do
  
defmodule JsonValidation do
  @true true
  @false false

  def validate(%{"oneOf" => [one | _]} = schema) do
    validate_one_of(one, schema)
  end

  def validate(_), do: :error

  defp validate_one_of(one, _) when is_map(one) do
    validator = fn
      %{"bar" => bar} when is_boolean(bar) -> :ok
      %{"foo" => foo} when is_boolean(foo) -> :ok
      _ -> :error
    end

    keys = Map.keys(one["properties"])
    required = one["required"] || []

    case Enum.all?(keys, &Map.has_key?(required, &1)) do
      true -> validator
      false -> fn _ -> :error end
    end
  end

  defp validate_one_of(_, _), do: :error
end

end
