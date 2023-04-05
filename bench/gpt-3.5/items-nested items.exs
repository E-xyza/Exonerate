defmodule :"items-nested items-gpt-3.5" do
  def validate(:null) do
    :ok
  end

  def validate(true) do
    :ok
  end

  def validate(false) do
    :ok
  end

  def validate(number) when is_number(number) do
    :ok
  end

  def validate("") do
    :error
  end

  def validate(string) when is_binary(string) do
    :ok
  end

  def validate([head | tail]) do
    items_validator = fn item ->
      case validate(item) do
        :ok -> :ok
        :error -> :error
      end
    end

    case head do
      [] when is_list(tail) ->
        validate(tail)

      _ when is_list(tail) ->
        if Enum.all?([head | tail], fn i -> i === head end) do
          :ok
        else
          :error
        end

      _ ->
        if Enum.all?([head | tail], items_validator) do
          :ok
        else
          :error
        end
    end
  end

  def validate(object) when is_map(object) do
    type = Map.get(object, "__type__", "object")

    case type do
      "object" ->
        properties_validator = fn {k, s} ->
          case Map.get(object, k, :undefined) do
            :undefined ->
              case Map.get(s, "required", false) do
                true -> :error
                false -> :ok
              end

            value ->
              validate_json_schema(s, value)
          end
        end

        properties = Map.get(object, "__properties__", [])

        if Enum.all?(properties, properties_validator) do
          :ok
        else
          :error
        end

      "array" ->
        items = Map.get(object, "__items__", [])

        if Enum.all?(items, &(validate_json_schema(&1, nil) == :ok)) do
          :ok
        else
          :error
        end

      "string" ->
        if is_binary(object) do
          :ok
        else
          :error
        end

      "number" ->
        if is_number(object) do
          :ok
        else
          :error
        end

      "boolean" ->
        case object do
          true or false -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_json_schema(schema, value) do
    validator = Map.get(schema, "__validator__", nil)

    if validator == nil do
      :error
    else
      validator.(value)
    end
  end
end
