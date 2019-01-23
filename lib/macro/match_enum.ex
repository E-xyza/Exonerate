defmodule Exonerate.Macro.MatchEnum do

  alias Exonerate.Macro.Method

  @type json :: Exonerate.json
  @type specmap :: %{optional(String.t) => json}
  @type defblock :: {:def, any, any}

  @spec match_enum(specmap, list(any), atom) :: [defblock]
  def match_enum(spec, enum_list, method) do
    esc_list = Macro.escape(enum_list)

    child = Method.concat(method, "_enclosing")

    [quote do
      def unquote(method)(val) do
        if val in unquote(esc_list) do
          unquote(child)(val)
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("enum")
     |> Exonerate.Macro.matcher(child))
  end

  @spec match_const(specmap, any, atom) :: [defblock]
  def match_const(spec, const, method) do
    const_val = Macro.escape(const)

    child = Method.concat(method, "_enclosing")

    [quote do
      def unquote(method)(val) do
        if val == unquote(const_val) do
          unquote(child)(val)
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("const")
     |> Exonerate.Macro.matcher(child))
  end

end
