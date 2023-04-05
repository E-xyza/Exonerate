defmodule :"single dependency-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{type: "object"} = obj) do
    case obj do
      %{additionalProperties: false, properties: props} ->
        if Map.keys(obj) -- [:additionalProperties, :properties] == [] and
             Map.values(props)
             |> Enum.all?(fn
               %{"type" => _} -> true
               _ -> false
             end) do
          :ok
        else
          :error
        end

      %{additionalProperties: true} ->
        :ok

      %{properties: props} ->
        if Map.keys(obj) -- [:properties] == [] and
             Map.values(props)
             |> Enum.all?(fn
               %{"type" => _} -> true
               _ -> false
             end) do
          :ok
        else
          :error
        end

      %{} ->
        :ok

      _ ->
        :error
    end
  end

  defp validate_object(_) do
    :error
  end
end