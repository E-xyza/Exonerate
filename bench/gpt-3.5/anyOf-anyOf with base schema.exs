defmodule :"anyOf-anyOf with base schema-gpt-3.5" do
  def validate(value) do
    case value do
      %{__struct__: Poison.Decoder.Nothing} ->
        :error

      %{"type" => "string", "minLength" => min_len, "maxLength" => max_len} ->
        case String.length(value) do
          len when len < min_len -> :error
          len when len > max_len -> :error
          _ -> :ok
        end

      %{"type" => "string", "minLength" => min_len} ->
        case String.length(value) do
          len when len < min_len -> :error
          _ -> :ok
        end

      %{"type" => "string", "maxLength" => max_len} ->
        case String.length(value) do
          len when len > max_len -> :error
          _ -> :ok
        end

      %{"type" => "string"} ->
        if is_binary(value) do
          :ok
        else
          :error
        end

      %{"type" => "number"} ->
        if is_number(value) do
          :ok
        else
          :error
        end

      %{"type" => "integer"} ->
        if is_integer(value) do
          :ok
        else
          :error
        end

      %{"type" => "array", "minItems" => min_items, "maxItems" => max_items} ->
        case length(value) do
          len when len < min_items -> :error
          len when len > max_items -> :error
          _ -> :ok
        end

      %{"type" => "array", "items" => items_schema} ->
        Enum.all?(value, &(validate(&1, items_schema) == :ok))

      %{"type" => "object", "properties" => props_schema} ->
        props_schema
        |> Enum.all?(fn {prop_name, prop_schema} ->
          case Map.get(value, prop_name) do
            nil -> true
            prop_value -> validate(prop_value, prop_schema) == :ok
          end
        end)

      %{"anyOf" => any_of_schemas} ->
        Enum.any?(any_of_schemas, &(validate(value, &1) == :ok))

      _ ->
        :error
    end
  end
end
