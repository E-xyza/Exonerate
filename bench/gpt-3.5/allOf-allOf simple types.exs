defmodule :"allOf simple types-gpt-3.5" do
  def validate({"allOf", [max_schema, min_schema]} = schema) do
    [maximum: maximum, minimum: minimum]
    |> Enum.map(fn {k, v} -> {k, v, Map.fetch(schema, k)} end)
    |> Enum.each(fn {k, v, {_, map_val}} ->
      error_msg = "Value must be < than #{v}." <> " Value provided was: #{map_val}."

      if Map.get(map_val, k, v + 1) > v do
        raise ArgumentError, error_msg
      end
    end)

    :ok
  end

  def validate({"type", "object"}) do
    def validate(object) when is_map(object) do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  def validate(_) do
    :error
  end
end
