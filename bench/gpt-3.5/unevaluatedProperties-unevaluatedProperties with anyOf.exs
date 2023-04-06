defmodule :"unevaluatedProperties-unevaluatedProperties with anyOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    case do_validate(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp do_validate(object) do
    case object["foo"] do
      nil -> false
      _ -> do_any_of(object)
    end
  end

  defp do_any_of(object) do
    any_of = object["anyOf"]

    if any_of do
      Enum.any?(any_of, fn map ->
        case do_schema(map, object) do
          true -> true
          false -> false
        end
      end)
    else
      do_properties(object)
    end
  end

  defp do_properties(object) do
    properties = object["properties"]

    if properties do
      Enum.all?(Map.keys(properties), fn key ->
        case do_property(key, properties, object) do
          true -> true
          false -> false
        end
      end)
    else
      true
    end
  end

  defp do_property(key, properties, object) do
    case properties[key] do
      %{"const" => value} -> object[key] == value
      %{"type" => "string"} -> is_binary(object[key])
      _ -> true
    end
  end

  defp do_schema(map, object) do
    case map do
      %{"properties" => properties, "required" => required} ->
        Enum.all?(required, fn key -> object[key] != nil end) and do_properties(properties)

      _ ->
        true
    end
  end
end