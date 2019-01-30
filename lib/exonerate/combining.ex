defmodule Exonerate.Combining do

  alias Exonerate.Method

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match_allof(map, list(any), atom) :: [defblock]
  def match_allof(base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "all_of_" <> inspect &1)
    base_child = Method.concat(method, "all_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = (0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1))
    ++ [base_child_fn]

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.flat_map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.matcher(spec, child_method)
      end
    )

    base_dependency = base_spec
    |> Map.delete("allOf")
    |> Exonerate.matcher(base_child)

    [quote do
      defp unquote(method)(val) do
        mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
        Exonerate.Reduce.allof(
          val,
          unquote(deps_fns),
          mismatch)
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_anyof(map, list(any), atom) :: [defblock]
  def match_anyof(base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "any_of_" <> inspect &1)
    base_child = Method.concat(method, "any_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = 0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.flat_map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.matcher(spec, child_method)
      end
    )

    base_dependency = base_spec
    |> Map.delete("anyOf")
    |> Exonerate.matcher(base_child)

    [quote do
      defp unquote(method)(val) do
        mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
        Exonerate.Reduce.anyof(
          val,
          unquote(deps_fns),
          unquote(base_child_fn),
          mismatch)
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_oneof(map, list(any), atom) :: [defblock]
  def match_oneof(base_spec, spec_list, method) do

    children_fn = &Method.concat(method, "one_of_" <> inspect &1)
    base_child = Method.concat(method, "one_of_base")
    base_child_fn = Method.to_lambda(base_child)

    deps_fns = 0..(Enum.count(spec_list) - 1)
    |> Enum.map(children_fn)
    |> Enum.map(&Method.to_lambda/1)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.flat_map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.matcher(spec, child_method)
      end
    )

    base_dependency = base_spec
    |> Map.delete("oneOf")
    |> Exonerate.matcher(base_child)

    [quote do
      defp unquote(method)(val) do
        mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
        Exonerate.Reduce.oneof(
          val,
          unquote(deps_fns),
          unquote(base_child_fn),
          mismatch)
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_not(map, any, atom) :: [defblock]
  def match_not(base_spec, inv_spec, method) do

    not_child = Method.concat(method, "not")
    not_fn = Method.to_lambda(not_child)

    base_child = Method.concat(method, "one_of_base")
    base_child_fn = Method.to_lambda(base_child)

    base_dependency = base_spec
    |> Map.delete("not")
    |> Exonerate.matcher(base_child)

    [quote do
      defp unquote(method)(val) do
        mismatch = Exonerate.mismatch(__MODULE__, unquote(method), val)
        Exonerate.Reduce.apply_not(
          val,
          unquote(not_fn),
          unquote(base_child_fn),
          mismatch)
      end
    end]
    ++ base_dependency
    ++ Exonerate.matcher(inv_spec, not_child)
  end

end
