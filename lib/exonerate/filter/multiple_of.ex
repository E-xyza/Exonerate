defmodule Exonerate.Filter.MultipleOf do
  @behaviour Exonerate.Filter

  def append_filter(factor, validation) when is_integer(factor) do
    %{validation | guards: [code(factor, validation) | validation.guards]}
  end

  defp code(factor, validation = %{types: [:integer]}) do
    quote do
      defp unquote(Exonerate.path_to_call(validation.path))(integer, path)
        when rem(integer, unquote(factor)) != 0 do
          Exonerate.mismatch(integer, path, guard: "multipleOf")
      end
    end
  end

  defp code(factor, validation) do
    quote do
      defp unquote(Exonerate.path_to_call(validation.path))(integer, path)
        when is_integer(integer) and rem(integer, unquote(factor)) != 0 do
          Exonerate.mismatch(integer, path, guard: "multipleOf")
      end
    end
  end
end
