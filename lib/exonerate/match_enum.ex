defmodule Exonerate.MatchEnum do

  alias Exonerate.Method

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match_enum(specmap, list(any), atom) :: [defblock]
  def match_enum(spec, enum_list, method) do
    esc_list = Macro.escape(enum_list)

    child = Method.concat(method, "_base")

    [quote do
      defp unquote(method)(val) do
        if val in unquote(esc_list) do
          unquote(child)(val)
        else
          Exonerate.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("enum")
     |> Exonerate.matcher(child))
  end

  @spec match_const(specmap, any, atom) :: [defblock]
  def match_const(spec, const, method) do
    const_val = Macro.escape(const)

    child = Method.concat(method, "_base")

    [quote do
      defp unquote(method)(val) do
        if val == unquote(const_val) do
          unquote(child)(val)
        else
          Exonerate.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("const")
     |> Exonerate.matcher(child))
  end

end
