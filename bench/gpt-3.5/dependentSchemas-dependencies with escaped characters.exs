defmodule :"dependencies with escaped characters-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp transform_schema({"type", "object"}) do
    {:ok, "is_map(object)"}
  end

  defp transform_schema(_) do
    {:error, "unsupported schema"}
  end

  defp validate_dependencies([], _) do
    :ok
  end

  defp validate_dependencies([{key, value} | rest], object) do
    case transform_schema(value) do
      {:ok, code} ->
        result = Code.eval_string(code)

        case result do
          :ok -> validate_dependencies(rest, object)
          _ -> {:error, "dependency validation failed for #{key}"}
        end

      {:error, msg} ->
        {:error, "invalid schema for #{key}: #{msg}"}
    end
  end

  def validate(json) do
    case Jason.decode(json) do
      {:ok, %{"dependentSchemas" => dependencies}} ->
        validate_dependencies(dependencies |> Enum.to_list(), Map.new())

      _ ->
        :error
    end
  end
end