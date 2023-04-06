defmodule :"unevaluatedItems-unevaluatedItems false-gpt-3.5" do
  def validate(arr) when is_list(arr) do
    case Enum.reduce(arr, {:ok, []}, fn item, {status, errors} ->
           case validate_item(item) do
             :ok -> {status, errors}
             :error -> {:error, ["invalid item"]}
           end
         end) do
      {:ok, _} -> :ok
      {:error, errors} -> {:error, errors}
    end
  end

  def validate(_) do
    {:error, ["not an array"]}
  end

  defp validate_item(item) when unquote(get_schema()) != [] do
    case validate_schema(item, hd(unquote(get_schema()))) do
      :ok -> :ok
      :error -> :error
    end
  end

  defp validate_item(_) do
    :ok
  end

  defp validate_schema(val, %{type: "array", unevaluatedItems: false} = schema)
       when is_list(val) do
    case validate_schema_list(val, schema) do
      :ok -> :ok
      :error -> :error
    end
  end

  defp validate_schema(_val, _schema) do
    :ok
  end

  defp validate_schema_list([], _schema) do
    :ok
  end

  defp validate_schema_list([item | rest], schema) do
    case validate_schema(item, schema) do
      :ok -> validate_schema_list(rest, schema)
      :error -> :error
    end
  end

  defp get_schema do
    %{type: "array", unevaluatedItems: false}
  end
end