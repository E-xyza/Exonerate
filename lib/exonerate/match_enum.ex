defmodule Exonerate.MatchEnum do

  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type parser   :: Parser.t

  @spec match_enum(specmap, parser, list(any), atom) :: parser
  def match_enum(spec, parser, enum_list, method) do
    esc_list = Macro.escape(enum_list)

    child = Method.concat(method, "_base")

    new_parser = struct!(Exonerate.Parser)

    dep = spec
    |> Map.delete("enum")
    |> Parser.match(new_parser, child)

    parser
    |> Parser.add_dependencies([dep])
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          if val in unquote(esc_list) do
            unquote(child)(val)
          else
            Exonerate.mismatch(__MODULE__, unquote(method), val)
          end
        end
      end])
  end

  @spec match_const(specmap, parser, any, atom) :: parser
  def match_const(spec, parser, const, method) do
    const_val = Macro.escape(const)

    child = Method.concat(method, "_base")

    new_parser = struct!(Exonerate.Parser)

    dep = spec
    |> Map.delete("const")
    |> Parser.match(new_parser, child)

    parser
    |> Parser.add_dependencies([dep])
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          if val == unquote(const_val) do
            unquote(child)(val)
          else
            Exonerate.mismatch(__MODULE__, unquote(method), val)
          end
        end
      end])
  end

end
