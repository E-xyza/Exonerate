defmodule :"const-const with [true] does not match [1]-gpt-3.5" do
  def validate(decoded_json) do
    case decoded_json do
      %{"const" => [true]} -> :ok
      %{"type" => "object"} -> &validate_object/1
      %{"type" => "array"} -> &validate_array/1
      %{"type" => "number"} -> &validate_number/1
      %{"type" => "string"} -> &validate_string/1
      %{"type" => "boolean"} -> &validate_boolean/1
      %{"type" => "null"} -> &validate_null/1
      _ -> :error
    end
  end

  defp validate_object(object) when is_map(object) do
    :ok
  end

  defp validate_object(_) do
    :error
  end

  defp validate_array(array) when is_list(array) do
    :ok
  end

  defp validate_array(_) do
    :error
  end

  defp validate_number(number) when is_number(number) do
    :ok
  end

  defp validate_number(_) do
    :error
  end

  defp validate_string(string) when is_binary(string) do
    :ok
  end

  defp validate_string(_) do
    :error
  end

  defp validate_boolean(boolean) when boolean in [true, false] do
    :ok
  end

  defp validate_boolean(_) do
    :error
  end

  defp validate_null(null) do
    :ok
  end

  defp validate_null(_) do
    :error
  end
end
