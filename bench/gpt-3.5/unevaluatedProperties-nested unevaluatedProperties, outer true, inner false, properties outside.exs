defmodule :"unevaluatedProperties-nested unevaluatedProperties, outer true, inner false, properties outside-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "foo") do
      true -> validate_foo(object["foo"])
      false -> :ok
    end
  end

  defp validate_foo(value) when is_binary(value) do
    :ok
  end

  defp validate_foo(_) do
    :error
  end
end
