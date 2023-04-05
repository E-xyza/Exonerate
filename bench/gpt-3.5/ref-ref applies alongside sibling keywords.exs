defmodule :"ref applies alongside sibling keywords-gpt-3.5" do
  def validate(json) when is_map(json) do
    if validate_properties(json) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(json) do
    case Map.get(json, "foo") do
      nil ->
        true

      array when is_list(array) ->
        if length(array) <= 2 do
          validate_refs(array)
        else
          false
        end

      _ ->
        false
    end
  end

  defp validate_refs(array) do
    refs = get_refs()
    Enum.all?(array, &Map.has_key?(refs, &1))
  end

  defp get_refs() do
    %{"#/$defs/reffed" => true}
  end
end