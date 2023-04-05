defmodule :"allOf with boolean schemas, all true-gpt-3.5" do
  def validate(object) when is_map(object) and true_schema(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp true_schema(object) do
    case object do
      %{} -> true
      [] -> true
      %{"allOf" => subschemas} -> Enum.all?(subschemas, &true_schema/1)
      _ -> false
    end
  end
end