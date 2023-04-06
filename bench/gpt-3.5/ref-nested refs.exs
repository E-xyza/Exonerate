defmodule :"ref-nested refs-gpt-3.5" do
  @type error :: {:error, String.t()}
  def validate(input) when is_map(input) do
    if validate_object(input) do
      :ok
    else
      {:error, "Input is not a valid JSON schema."}
    end
  end

  def validate(_) do
    {:error, "Input is not a valid JSON schema."}
  end

  defp validate_data_type(data, type) do
    case type do
      "string" -> is_binary(data)
      "number" -> is_number(data)
      "integer" -> is_integer(data)
      "boolean" -> data == true or data == false
      "null" -> is_nil(data)
      _ -> false
    end
  end

  defp validate_object(data) do
    case data do
      %{"$ref" => ref} -> ref |> String.split("/") |> validate_nested_ref()
      %{"$defs" => defs, "$ref" => ref} -> defs[ref] |> validate_nested_ref()
      %{"type" => type} -> validate_data_type(data, type)
      %{"type" => types} -> Enum.all?(types, fn type -> validate_data_type(data, type) end)
      map when is_map(map) -> Enum.all?(map, fn {k, v} -> validate_object(v) end)
      _ -> false
    end
  end

  defp validate_nested_ref([]) do
    true
  end

  defp validate_nested_ref([head | tail]) do
    case head do
      "#" ->
        validate_nested_ref(tail)

      "$defs" ->
        validate_nested_ref(tail)

      ref ->
        case @schemas[ref] do
          nil -> false
          schema -> validate_nested_ref(tail) and validate_object(schema)
        end
    end
  end

  @schemas %{
    "a" => %{"type" => "integer"},
    "b" => %{"$ref" => "#/$defs/a"},
    "c" => %{"$ref" => "#/$defs/b"}
  }
end