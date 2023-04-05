defmodule :"not-gpt-3.5" do
  def validate(json) do
    case json do
      %{type: "integer"} ->
        :error

      %{type: type} when is_atom(type) ->
        "validate_#{type}" |> String.to_existing_atom() |> apply([json])

      %{enum: enum} ->
        validate_enum(json, enum)

      %{not: not_schema} ->
        validate_not(json, not_schema)

      _ ->
        :ok
    end
  end

  def validate_object(json) when is_map(json) do
    :ok
  end

  def validate_object(_json) do
    :error
  end

  def validate_array(json) when is_list(json) do
    :ok
  end

  def validate_array(_json) do
    :error
  end

  def validate_string(json) when is_binary(json) do
    :ok
  end

  def validate_string(_json) do
    :error
  end

  def validate_number(json) when is_number(json) do
    :ok
  end

  def validate_number(_json) do
    :error
  end

  def validate_boolean(true) do
    :ok
  end

  def validate_boolean(false) do
    :ok
  end

  def validate_boolean(_) do
    :error
  end

  def validate_enum(json, enum) when enum |> Enum.member?(json) do
    :ok
  end

  def validate_enum(_, _) do
    :error
  end

  def validate_not(json, not_schema) do
    case validate(not_schema) do
      :ok -> :error
      _ -> :ok
    end
  end
end
