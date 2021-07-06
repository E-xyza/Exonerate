defmodule Exonerate.Filter.MinProperties do
  @behaviour Exonerate.Filter

  def append_filter(minimum, validation) when is_integer(minimum) do
    %{validation | guards: [code(minimum, validation) | validation.guards]}
  end

  defp code(minimum, validation = %{types: [:object]}) do
    quote do
      defp unquote(Exonerate.path_to_call(validation.path))(map, path)
        when :erlang.map_size(map) < unquote(minimum) do
          Exonerate.mismatch(map, path, guard: "minProperties")
      end
    end
  end

  defp code(minimum, validation) do
    quote do
      defp unquote(Exonerate.path_to_call(validation.path))(map, path)
        when is_map(map) and :erlang.map_size(map) < unquote(minimum) do
          Exonerate.mismatch(map, path, guard: "minProperties")
      end
    end
  end
end
