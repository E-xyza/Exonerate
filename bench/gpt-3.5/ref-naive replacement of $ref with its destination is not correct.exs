defmodule :"naive replacement of $ref with its destination is not correct-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp validate_ref(object, refpath) do
    case refpath do
      [] ->
        :ok

      [refkey | refrest] ->
        case Map.fetch(object, "$defs") do
          {:ok, defs} -> validate_ref_def(defs, refkey, refrest)
          :error -> :error
        end
    end
  end

  defp validate_ref_def(defs, refkey, refrest) do
    case Map.fetch(defs, refkey) do
      {:ok, def} ->
        case Map.fetch(def, "type") do
          {:ok, "string"} -> validate_ref(refrest)
          _ -> :error
        end

      :error ->
        :error
    end
  end

  def validate(json) do
    case json do
      %{"enum" => [%{"$ref" => refpath}]} ->
        validate_ref(
          json,
          String.split(
            refpath,
            "/"
          )
        )

      %{"type" => "object"} ->
        validate_map(json)

      %{"type" => "string"} ->
        :ok

      _ ->
        :error
    end
  end

  defp validate_map(map) do
    case Map.keys(map) do
      ["$defs", "enum"] -> :ok
      _ -> :error
    end
  end
end