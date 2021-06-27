defmodule Exonerate.Filter.Minimum do
  @behaviour Exonerate.Filter

  def append_filter(minimum, validation) when is_number(minimum) do
    %{validation | guards: [code(minimum, validation) | validation.guards]}
  end

  @numeric_types [[:integer], [:number], [:integer, :number], [:number, :integer]]

  defp code(minimum, validation = %{types: types}) when types in @numeric_types do
    quote do
      defp unquote(Exonerate.path(validation.path))(number, path)
        when number < unquote(minimum) do
          Exonerate.mismatch(number, path, guard: "minimum")
      end
    end
  end

  defp code(minimum, validation) do
    quote do
      defp unquote(Exonerate.path(validation.path))(number, path)
        when is_number(number) and number < unquote(minimum) do
          Exonerate.mismatch(number, path, guard: "minimum")
      end
    end
  end
end
