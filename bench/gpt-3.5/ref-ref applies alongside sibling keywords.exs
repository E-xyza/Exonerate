defmodule :"ref-ref applies alongside sibling keywords-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.get(object, "foo") do
      nil ->
        :ok

      array when is_list(array) ->
        if length(array) <= 2 do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end
end
