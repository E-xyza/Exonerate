defmodule :"type-string type matches strings-gpt-3.5" do
  def validate(data) when is_binary(data) do
    :ok
  end

  def validate(data) when is_list(data) do
    Enum.reduce(data, :ok, fn item, acc ->
      if is_binary(item) do
        acc
      else
        :error
      end
    end)
  end

  def validate(data) when is_map(data) do
    if Map.keys(data) == [:type] do
      case Map.fetch(data, :type) do
        {:ok, "string"} -> :ok
        {:ok, "object"} -> :ok when is_map(data)
        _ -> :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
