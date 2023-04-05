defmodule :"relative pointer ref to object-gpt-3.5" do
  def validate(
        %{
          "properties" => %{
            "bar" => %{"$ref" => "#/properties/foo"},
            "foo" => %{"type" => "integer"}
          }
        } = object
      ) do
    case validate_props(object, ["bar", "foo"]) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_props(object, props) when is_list(props) do
    case props do
      [prop | rest] ->
        case Map.has_key?(object, prop) do
          true -> validate_props(Map.get(object, prop), rest)
          false -> false
        end

      [] ->
        true
    end
  end

  defp validate_props(_, _) do
    false
  end
end
