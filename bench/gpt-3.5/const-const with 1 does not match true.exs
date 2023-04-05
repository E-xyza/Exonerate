defmodule :"const-const with 1 does not match true-gpt-3.5" do
  def validate(schema_object) do
    case schema_object do
      %{"const" => 1} -> :ok
      %{"type" => "object"} -> &validate_object/1
      _ -> :error
    end
  end

  defp validate_object(object) when is_map(object) do
    :ok
  end

  defp validate_object(_) do
    :error
  end
end
