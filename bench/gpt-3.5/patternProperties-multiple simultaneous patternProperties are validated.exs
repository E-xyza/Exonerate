defmodule :"multiple simultaneous patternProperties are validated-gpt-3.5" do
  def validate(json) when is_map(json) do
    case validate_object(json, %{
           "patternProperties" => %{"a*" => %{"type" => "integer"}, "aaa*" => %{"maximum" => 20}}
         }) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object, schema) when is_map(schema) do
    Map.from_struct(object, &validate_property/1, schema)
  end

  defp validate_property({prop, value}, schema) when is_map(schema) do
    validate_property(prop, value, schema[prop])
  end

  defp validate_property(_, _, _) do
    true
  end

  defp validate_property(prop, value, %{"type" => "integer"}) when is_integer(value) do
    true
  end

  defp validate_property(_, _, %{"type" => "integer"}) do
    false
  end

  defp validate_property(prop, value, %{"maximum" => max}) when max >= value do
    true
  end

  defp validate_property(_, _, %{"maximum" => _}) do
    false
  end

  defp validate_property(_, _, _) do
    true
  end
end
