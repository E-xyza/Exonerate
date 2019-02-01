defmodule Exonerate.MatchEnum do

  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec match_enum(Parser.t, specmap, list(any), atom) :: Parser.t
  def match_enum(parser, spec, enum_list, method) do
    esc_list = Macro.escape(enum_list)

    child = Method.concat(method, "_base")

    new_parser = struct!(Exonerate.Parser)

    child_spec = Map.delete(spec, "enum")
    dep = Parser.match(new_parser, child_spec, child)

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

  @spec match_const(Parser.t, specmap, any, atom) :: Parser.t
  def match_const(parser, spec, const, method) do
    const_val = Macro.escape(const)

    child = Method.concat(method, "_base")

    new_parser = struct!(Exonerate.Parser)

    child_spec = Map.delete(spec, "const")

    dep = Parser.match(new_parser, child_spec, child)

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
