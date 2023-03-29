defmodule :"ref creates new scope when adjacent to keywords-gpt-3.5" do
  def validate(decoded_json) when is_map(decoded_json) do
    case decoded_json do
      %{"$defs" => defs, "$ref" => ref, "properties" => props} ->
        case Map.fetch(defs, ref) do
          {:ok, def} ->
            props_valid = props |> Map.keys() |> Enum.all?(&Map.has_key?(def["properties"], &1))

            if props_valid do
              :ok
            else
              :error
            end

          :error ->
            :error
        end

      %{"type" => "object"} ->
        :ok

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
