defmodule :"unevaluatedProperties with not-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object) do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    properties_errors = validate_properties(object)
    required_errors = validate_required(object)
    not_conditions_errors = validate_not_conditions(object)
    properties_errors ++ required_errors ++ not_conditions_errors
  end

  defp validate_properties(object) do
    schema_properties = :proplists.get_value(:properties, schema(), [])

    for {key, sub_schema} <- schema_properties do
      validate_property(key, sub_schema, object)
    end
  end

  defp validate_property(key, sub_schema, object) do
    case Map.get(object, key) do
      value when is_nil(value) ->
        [{"#{key} is missing", []}]

      value ->
        validate_sub_schema(sub_schema, value)
        |> Enum.map(fn {error, path} -> {"#{key}.#{error}", path} end)
    end
  end

  defp validate_required(object) do
    required_keys = :proplists.get_value(:required, schema(), [])

    for key <- required_keys do
      validate_required_key(key, object)
    end
  end

  defp validate_required_key(key, object) do
    case Map.has_key?(object, key) do
      true -> []
      false -> [{"#{key} is required", []}]
    end
  end

  defp validate_not_conditions(object) do
    not_conditions = :proplists.get_value(:not, schema(), [])

    case not_conditions do
      [] ->
        []

      _ ->
        validate_sub_schema(not_conditions, object)
        |> Enum.map(fn {error, path} -> {error, ["not" | path]} end)
    end
  end

  defp validate_sub_schema(sub_schema, value, path \\ []) do
    case sub_schema do
      %{"type" => "object"} ->
        validate_object(value)
        |> Enum.map(fn {error, sub_path} ->
          {error, ["#{path |> Enum.join(".")}|#{sub_path |> Enum.join(".")}"]}
        end)

      %{"type" => "string"} ->
        case is_binary(value) do
          true -> []
          false -> [{"must be a string", path}]
        end

      %{"const" => const} ->
        case value === const do
          true -> []
          false -> [{"must be exactly '#{inspect(const)}'", path}]
        end

      %{"properties" => properties} ->
        validate_properties(value, properties, path)

      %{"required" => required} ->
        validate_required(value, required, path)

      %{"not" => not_conditions} ->
        validate_not_conditions(value, not_conditions, path)

      _ ->
        []
    end
  end

  defp validate_properties(value, properties, path) do
    schema_properties = :proplists.get_value(:properties, properties, [])

    for {key, sub_schema} <- schema_properties do
      validate_property(key, sub_schema, value, path) |> List.flatten()
    end
  end

  defp validate_property(key, sub_schema, value, path) do
    case Map.get(value, key) do
      sub_value when is_nil(sub_value) ->
        [{"#{key} is missing", path}]

      sub_value ->
        validate_sub_schema(sub_schema, sub_value, path ++ [key])
        |> Enum.map(fn {error, sub_path} -> {"#{key}.#{error}", sub_path} end)
    end
  end

  defp validate_required(value, required, path) do
    required_errors =
      for key <- required do
        validate_required_key(key, value, path)
      end

    List.flatten(required_errors)
  end

  defp validate_required_key(key, value, path) do
    case Map.has_key?(value, key) do
      true -> []
      false -> [{"#{key} is required", path}]
    end
  end

  defp validate_not_conditions(value, not_conditions, path) do
    case validate_sub_schema(not_conditions, value, path) do
      [] -> [{"#{inspect(not_conditions)} must not be valid", path}]
      _ -> []
    end
  end

  defp schema do
    %{
      "not" => %{
        "not" => %{"properties" => %{"bar" => %{"const" => "bar"}}, "required" => ["bar"]}
      },
      "properties" => %{"foo" => %{"type" => "string"}},
      "type" => "object",
      "unevaluatedProperties" => false
    }
  end
end