defmodule Exonerate.MatchNumber do

  alias Exonerate.BuildCond
  require Logger

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match_int(map, atom, boolean) :: [defblock]
  def match_int(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_cond_int(method)
    |> BuildCond.build

    int_match = quote do
      defp unquote(method)(val) when is_integer(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [int_match | Exonerate.never_matches(method)]
    else
      [int_match]
    end
  end

  @spec build_cond_int(specmap, atom) :: [BuildCond.condclause]
  defp build_cond_int(spec = %{"multipleOf" => base}, method) do
    [
      {
        quote do rem(val, unquote(base)) != 0 end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("multipleOf")
      |> build_cond_int(method)
    ]
  end
  defp build_cond_int(spec, module), do: build_cond(spec, module)

  @spec match(map, atom, boolean) :: [defblock]
  def match(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(method)
    |> BuildCond.build

    num_match = quote do
      defp unquote(method)(val) when is_number(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [num_match | Exonerate.never_matches(method)]
    else
      [num_match]
    end
  end

  @spec build_cond(specmap, atom) :: [BuildCond.condclause]
  defp build_cond(spec = %{"multipleOf" => base}, method) do
    Logger.warn("you are building multipleOf against a \"number\" type in your JsonSchema.  Consider using integer")
    [
      #disallow multipleOf on non-integer values
      {
        quote do !is_integer(val) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      },
      {
        quote do rem(val, unquote(base)) != 0 end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("multipleOf")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"minimum" => cmp}, method) do
    [
      {
        quote do val < unquote(cmp) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minimum")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"exclusiveMinimum" => cmp}, method) do
    [
      {
        quote do val <= unquote(cmp) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMinimum")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"maximum" => cmp}, method) do
    [
      {
        quote do val > unquote(cmp) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maximum")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"exclusiveMaximum" => cmp}, method) do
    [
      {
        quote do val >= unquote(cmp) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMaximum")
      |> build_cond(method)
    ]
  end
  defp build_cond(_spec, _method), do: []

end
