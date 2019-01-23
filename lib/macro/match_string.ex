defmodule Exonerate.Macro.MatchString do

  alias Exonerate.Macro.BuildCond

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  def match(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_cond(method)
    |> BuildCond.build

    # TODO: make length value only appear if we have a length check.

    str_match = quote do
      def unquote(method)(val) when is_binary(val) do
        length = String.length(val)
        unquote(cond_stmt)
      end
    end

    if terminal do
      [str_match | Exonerate.Macro.never_matches(method)]
    else
      [str_match]
    end
  end

  @spec build_cond(specmap, atom) :: [BuildCond.cond_clauses]
  defp build_cond(spec = %{"maxLength" => length}, method) do
    [
      {
        quote do length > unquote(length) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
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
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
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
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("pattern")
      |> build_cond(method)
    ]
  end
  defp build_cond(_spec, _method), do: []


end
