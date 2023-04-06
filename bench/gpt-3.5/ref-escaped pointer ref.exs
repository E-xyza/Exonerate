defmodule :"ref-escaped pointer ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_properties(object)
  end

  def validate(object) do
    :error
  end

  defp validate_properties(object) do
    case Map.keys(object) do
      ["percent", "slash", "tilde"] -> validate_ref_properties(object)
      _ -> :error
    end
  end

  defp validate_ref_properties(object) do
    case {Map.get(object, "percent"), Map.get(object, "slash"), Map.get(object, "tilde")} do
      {percent_ref, slash_ref, tilde_ref} ->
        case {validate_ref(percent_ref, "#/$defs/percent%field"),
              validate_ref(slash_ref, "#/$defs/slash~1field"),
              validate_ref(tilde_ref, "#/$defs/tilde~0field")} do
          {:ok, :ok, :ok} -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_ref(ref, pointer) do
    cond do
      ref == nil -> :ok
      Map.get(ref, "$ref") == pointer -> :ok
      true -> :error
    end
  end
end
