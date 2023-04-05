defmodule :"remote ref, containing refs itself-gpt-3.5" do
  def validate(%{"$ref" => _} = _json) do
    :error
  end

  def validate(%{"type" => "null"} = json) do
    validate_null(json)
  end

  def validate(%{"type" => "boolean"} = json) do
    validate_boolean(json)
  end

  def validate(%{"type" => "number"} = json) do
    validate_number(json)
  end

  def validate(%{"type" => "integer"} = json) do
    validate_integer(json)
  end

  def validate(%{"type" => "string"} = json) do
    validate_string(json)
  end

  def validate(%{"type" => "array"} = json) do
    validate_array(json)
  end

  def validate(%{"type" => "object"} = json) do
    validate_object(json)
  end

  def validate(_json) do
    :error
  end

  def validate_null(null) when is_nil(null) do
    :ok
  end

  def validate_null(_) do
    :error
  end

  def validate_boolean(boolean) when boolean in [true, false] do
    :ok
  end

  def validate_boolean(_) do
    :error
  end

  def validate_number(number) when is_number(number) do
    :ok
  end

  def validate_number(_) do
    :error
  end

  def validate_integer(integer) when is_integer(integer) do
    :ok
  end

  def validate_integer(_) do
    :error
  end

  def validate_string(string) when is_binary(string) do
    :ok
  end

  def validate_string(_) do
    :error
  end

  def validate_array([]) do
    :ok
  end

  def validate_array([head | tail]) do
    case validate(head) do
      :ok -> validate_array(tail)
      error -> error
    end
  end

  def validate_array(_) do
    :error
  end

  def validate_object(%{}) do
    :ok
  end

  def validate_object(object) when is_map(object) do
    for {key, value} <- object do
      validate(key) == :ok and validate(value)
    end

    :ok
  end

  def validate_object(_) do
    :error
  end
end