defmodule :"ref-refs with quote-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok |> validate_properties(object) |> validate_refs(object)
  end

  def validate(_) do
    :error
  end

  defp validate_properties(result, object) do
    case Map.keys(object) do
      [] ->
        result

      _ ->
        :error
        |> add_error("Object has properties not defined in schema")
        |> validate_properties(object)
    end
  end

  defp validate_refs(result, object) do
    case Map.get(object, "$ref") do
      nil ->
        result

      ref ->
        path = convert_ref(ref)

        case resolve_ref_path(path) do
          {:ok, schema} -> validate(schema)
          {:error, message} -> :error |> add_error(message) |> validate_refs(object)
        end
    end
  end

  defp convert_ref(ref) do
    ref
    |> String.replace("\\\"", "\"")
    |> String.replace("%22", "\"")
    |> String.replace("#/", "")
    |> String.split("/")
  end

  defp resolve_ref_path([]) do
    {:error, "Empty reference path"}
  end

  defp resolve_ref_path([key | keys]) do
    case Map.get(@schema, key) do
      nil ->
        {:error, "Invalid reference path"}

      value when is_map(value) ->
        if Enum.empty?(keys) do
          {:ok, value}
        else
          resolve_ref_path(keys, value)
        end

      _ ->
        {:error, "Invalid reference path"}
    end
  end

  defp add_error(result, message) do
    case result do
      {:ok, _} -> {:error, message}
      {:error, errors} -> {:error, [message | errors]}
    end
  end

  @schema %{
    "$defs" => %{"foo\"bar" => %{"type" => "number"}},
    "properties" => %{"foo\"bar" => %{"$ref" => "#/$defs/foo%22bar"}}
  }
end