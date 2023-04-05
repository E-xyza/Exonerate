defmodule :"nested refs-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "$ref") do
      true -> validate_ref(object["$ref"], object)
      false -> validate_type(object["type"], object)
    end
  end

  defp validate_ref(ref, object) do
    validate_object(get_ref(ref, object))
  end

  defp validate_type("integer", object) when is_integer(object) do
    :ok
  end

  defp validate_type("number", object) when is_number(object) do
    :ok
  end

  defp validate_type("string", object) when is_binary(object) do
    :ok
  end

  defp validate_type("boolean", object) when object in [true, false] do
    :ok
  end

  defp validate_type("null", object) when is_nil(object) do
    :ok
  end

  defp validate_type("object", object) when is_map(object) do
    validate_object(object)
  end

  defp validate_type("array", object) when is_list(object) do
    validate_array(object)
  end

  defp validate_type("array", _) do
    :error
  end

  defp validate_type(_type, _object) do
    :error
  end

  defp validate_array([]) do
    :ok
  end

  defp validate_array([object | rest]) do
    case validate_object(object) do
      :error -> :error
      _ -> validate_array(rest)
    end
  end

  defp get_ref(ref, object) do
    [_, defs | keys] =
      String.split(
        ref,
        "/"
      )

    defs =
      List.to_tuple(
        String.split(
          defs,
          "-"
        )
      )

    key_path =
      Enum.reduce(keys, defs, fn key, defs ->
        {_, key} = Integer.parse(key)
        Enum.at(defs, key)
      end)

    Enum.reduce(key_path, object, &Map.get(&2, &1))
  end
end
