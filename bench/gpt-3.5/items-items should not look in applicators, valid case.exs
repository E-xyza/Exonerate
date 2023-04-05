defmodule :"items should not look in applicators, valid case-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate(object, schema())
  end

  def validate(_) do
    :error
  end

  defp schema do
    %{"allOf" => [%{"prefixItems" => [%{"minimum" => 3}]}], "items" => %{"minimum" => 5}}
  end

  defp validate(object, schema) do
    case validate_allOf(object, schema["allOf"]) do
      {:ok, _} = result -> validate_items(result, schema["items"])
      result -> result
    end
  end

  defp validate_allOf(object, []) do
    {:ok, object}
  end

  defp validate_allOf(object, [validator | rest_validators]) do
    case validate_prefixItems(object, validator["prefixItems"]) do
      {:ok, _} = result ->
        case validate_allOf(object, rest_validators) do
          {:ok, _} = nested_result -> nested_result
          _ -> result
        end

      result ->
        result
    end
  end

  defp validate_prefixItems([], _) do
    {:ok, []}
  end

  defp validate_prefixItems([first | rest], []) do
    case validate_object(first, %{"minimum" => 3}) do
      :ok ->
        case validate_prefixItems(rest, []) do
          {:ok, _} = result -> result
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_prefixItems([first | rest], [validator | rest_validators]) do
    case validate_object(first, validator) do
      :ok ->
        case validate_prefixItems(rest, rest_validators) do
          {:ok, _} = result -> result
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_items([], _) do
    {:ok, []}
  end

  defp validate_items([first | rest], validator) do
    case validate_object(first, validator) do
      :ok ->
        case validate_items(rest, validator) do
          {:ok, _} = result -> result
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_object(_, %{"minimum" => minimum}) when minimum != nil do
    {:ok} = validate_object(_, %{"type" => "number"})

    case validate_object(_, %{"minimum" => minimum}) do
      {:ok} = result -> result
      _ -> :error
    end
  end

  defp validate_object(_, %{"type" => "number"}) do
    :ok
  end

  defp validate_object(_, %{"type" => "object"}) do
    :ok
  end

  defp validate_object(_, %{"type" => "array"}) do
    :ok
  end

  defp validate_object(_, _) do
    :error
  end
end