defmodule Exonerate.Filter.ExclusiveMaximum do
  @behaviour Exonerate.Filter

  def append_filter(maximum, validation) when is_number(maximum) do
    %{validation | guards: [code(maximum, validation) | validation.guards]}
  end

  @numeric_types [[:integer], [:number], [:integer, :number], [:number, :integer]]

  defp code(maximum, validation = %{types: types}) when types in @numeric_types do
    quote do
      defp unquote(Exonerate.path(validation.path))(number, path)
        when number >= unquote(maximum) do
          Exonerate.mismatch(number, path, guard: "exclusiveMaximum")
      end
    end
  end

  defp code(maximum, validation) do
    quote do
      defp unquote(Exonerate.path(validation.path))(number, path)
        when is_number(number) and number >= unquote(maximum) do
          Exonerate.mismatch(number, path, guard: "exclusiveMaximum")
      end
    end
  end
end
