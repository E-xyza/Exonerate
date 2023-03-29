defmodule :"pattern validation-gpt-3.5" do
  def validate(value) when is_map(value) do
    validate_object(value)
  end

  def validate(value) when is_list(value) do
    validate_array(value)
  end

  def validate(value) when is_binary(value) do
    validate_string(value)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case get_required_fields(object) do
      {:ok, required} ->
        case Map.keys(object) -- required do
          [] -> :ok
          extra_keys -> {:error, "extra keys: #{inspect(extra_keys)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_required_fields(object) do
    case get_property(object, "required") do
      {:ok, required} when is_list(required) -> {:ok, required}
      {:ok, _} -> {:error, "invalid 'required' property"}
      {:error, _} -> {:ok, []}
    end
  end

  defp validate_array(array) do
    case get_property(array, "items") do
      {:ok, items} when is_list(items) ->
        case Enum.reduce(items, :ok, fn item, acc ->
               case acc do
                 :ok -> validate(item)
                 {:error, reason} -> {:error, reason}
               end
             end) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:ok, _} ->
        {:error, "'items' property is not a list"}

      {:error, _} ->
        :ok
    end
  end

  defp validate_string(string) do
    case get_property(string, "pattern") do
      {:ok, pattern} when is_binary(pattern) ->
        case String.match?(string, pattern) do
          true -> :ok
          false -> {:error, "string does not match pattern: #{inspect(pattern)}"}
        end

      {:ok, _} ->
        {:error, "'pattern' property is not a binary"}

      {:error, _} ->
        :ok
    end
  end

  defp get_property(object, name) do
    case Map.get(object, name) do
      value when value !== nil -> {:ok, value}
      _ -> {:error, "missing #{name} property"}
    end
  end
end
