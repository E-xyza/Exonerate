defmodule Exonerate.Filter.MaxProperties do
  @behaviour Exonerate.Filter

  def append_filter(maximum, validation) when is_integer(maximum) do
    %{validation | guards: [code(maximum, validation) | validation.guards]}
  end

  defp code(maximum, validation = %{types: [:object]}) do
    quote do
      defp unquote(Exonerate.path(validation.path))(map, path)
        when :erlang.map_size(map) > unquote(maximum) do
          Exonerate.mismatch(map, path, guard: "maxProperties")
      end
    end
  end

  defp code(maximum, validation) do
    quote do
      defp unquote(Exonerate.path(validation.path))(map, path)
        when is_map(map) and :erlang.map_size(map) > unquote(maximum) do
          Exonerate.mismatch(map, path, guard: "maxProperties")
      end
    end
  end
end
