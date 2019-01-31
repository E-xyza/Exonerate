defmodule Exonerate.MatchString do

  alias Exonerate.BuildCond

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match(specmap, module, atom) :: [defblock]
  def match(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(method)
    |> BuildCond.build

    length_stmt = if (Map.has_key?(spec, "maxLength") ||
                      Map.has_key?(spec, "minLength") ) do
      quote do
        length = String.length(val)
      end
    else
      nil
    end

    str_match = quote do
      defp unquote(method)(val) when is_binary(val) do
        unquote(length_stmt)
        unquote(cond_stmt)
      end
    end

    if terminal do
      [str_match | Exonerate.never_matches(method)]
    else
      [str_match]
    end
  end

  @spec build_cond(specmap, atom) :: [BuildCond.condclause]
  defp build_cond(spec = %{"maxLength" => length}, method) do
    [
      {
        quote do length > unquote(length) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maxLength")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"minLength" => length}, method) do
    [
      {
        quote do length < unquote(length) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minLength")
      |> build_cond(method)
    ]
  end
  defp build_cond(spec = %{"pattern" => patt}, method) do
    [
      {
        quote do !(Regex.match?(sigil_r(<<unquote(patt)>>, ''), val)) end,
        quote do Exonerate.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("pattern")
      |> build_cond(method)
    ]
  end
  defp build_cond(_spec, _method), do: []

end
