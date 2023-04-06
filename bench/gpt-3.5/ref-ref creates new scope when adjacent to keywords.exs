defmodule :"ref-ref creates new scope when adjacent to keywords-gpt-3.5" do
  def validate(%{}, _) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"type" => "object"} = object) do
    cond do
      is_map(object) -> :ok
      true -> :error
    end
  end

  def validate(_) do
    :error
  end

  def validate(%{"$ref" => "#/$defs/A"} = object) do
    validate(%{}, %{"$defs" => %{"A" => %{"unevaluatedProperties" => false}}})
  end

  def validate(%{"properties" => props} = object) do
    for {name, schema} <- props do
      case validate_schema(schema) do
        :ok -> :ok
        :error -> return_error(name, schema)
      end
    end
  end

  def validate_schema(%{"type" => "string"} = schema) do
    cond do
      is_binary(schema) -> :ok
      true -> :error
    end
  end

  def validate_schema(_) do
    :error
  end

  def return_error(name, schema) do
    {:error, "#{name} has invalid schema: #{inspect(schema)}"}
  end
end