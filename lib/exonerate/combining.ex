defmodule Exonerate.Combining do

  alias Exonerate.Method
  alias Exonerate.Parser

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap

  @spec match_allof(Parser.t, map, list(any), atom) :: Parser.t
  def match_allof(parser, base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "all_of_" <> inspect &1)
    base_child = Method.concat(method, "all_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = (0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1))
    ++ [base_child_fn]

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Parser.match(parser, spec, child_method)
      end
    )

    rest_spec = Map.delete(base_spec, "allOf")
    base_dependency = Parser.match(parser, rest_spec, base_child)

    parser
    |> Parser.add_dependencies([base_dependency | dependencies])
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
          Exonerate.Reduce.allof(
            val,
            unquote(deps_fns),
            mismatch)
        end
      end])
  end

  @spec match_anyof(Parser.t, map, list(any), atom) :: Parser.t
  def match_anyof(parser, base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "any_of_" <> inspect &1)
    base_child = Method.concat(method, "any_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = 0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Parser.match(parser, spec, child_method)
      end
    )

    rest_spec = Map.delete(base_spec, "anyOf")
    base_dependency = Parser.match(parser, rest_spec, base_child)

    parser
    |> Parser.add_dependencies([base_dependency | dependencies])
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
          Exonerate.Reduce.anyof(
            val,
            unquote(deps_fns),
            unquote(base_child_fn),
            mismatch)
        end
      end])
  end

  @spec match_oneof(Parser.t, map, list(any), atom) :: Parser.t
  def match_oneof(parser, base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "one_of_" <> inspect &1)
    base_child = Method.concat(method, "one_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = 0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Parser.match(parser, spec, child_method)
      end
    )

    rest_spec = Map.delete(base_spec, "oneOf")
    base_dependency = Parser.match(parser, rest_spec, base_child)

    parser
    |> Parser.add_dependencies([base_dependency | dependencies])
    |> Parser.append_blocks([
      quote do
        defp unquote(method)(val) do
          mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
          Exonerate.Reduce.oneof(
            val,
            unquote(deps_fns),
            unquote(base_child_fn),
            mismatch)
        end
      end])
  end

  @spec match_not(Parser.t, map, any, atom) :: Parser.t
  def match_not(parser, base_spec, inv_spec, method) do

    not_child = Method.concat(method, "not")
    not_fn = Method.to_lambda(not_child)

    base_child = Method.concat(method, "one_of_base")
    base_child_fn = Method.to_lambda(base_child)

    rest_spec = Map.delete(base_spec, "not")

    base_dependency = Parser.match(parser, rest_spec, base_child)

    new_parser = struct!(Exonerate.Parser)
    inv_dependency = Parser.match(new_parser, inv_spec, not_child)

    parser
    |> Parser.add_dependencies([base_dependency, inv_dependency])
    |> Parser.append_blocks([quote do
      defp unquote(method)(val) do
        mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
        Exonerate.Reduce.apply_not(
          val,
          unquote(not_fn),
          unquote(base_child_fn),
          mismatch)
      end
    end])
  end

end
