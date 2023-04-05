defmodule :"additionalProperties-additionalProperties being false does not allow other properties-gpt-3.5" do
  def validate(obj) when is_map(obj) do
    case %{properties: props, patternProperties: pat_props, additionalProperties: add_props} =
           &(Map.from_struct() / 1.(&1)) do
      %{additionalProperties: false} ->
        Enum.reduce(
          props,
          Enum.reduce(pat_props, :ok, fn {pat, _}, acc ->
            case Regex.match?(~r/^#{pat}/, Map.keys(obj)) do
              true -> acc
              false -> :error
            end
          end),
          fn {key, _val}, acc ->
            if Map.has_key?(obj, key) do
              acc
            else
              :error
            end
          end
        )

      %{additionalProperties: true} ->
        Enum.reduce(
          props,
          Enum.reduce(pat_props, :ok, fn {pat, _}, acc ->
            case Regex.match?(~r/^#{pat}/, Map.keys(obj)) do
              true -> acc
              false -> :ok
            end
          end),
          fn {key, _val}, acc ->
            if Map.has_key?(obj, key) do
              acc
            else
              :ok
            end
          end
        )

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
