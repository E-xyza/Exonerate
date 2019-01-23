defmodule Exonerate.Macro.Combining do

  alias Exonerate.Macro.Method

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec match_allof(map, list(any), atom) :: [defblock]
  def match_allof(base_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    children_fn = &Method.concat(method, "_allof_" <> inspect &1)
    base_child = Method.concat(method, "_allof_base")

    deps_list = [base_child | Enum.map(idx_range, children_fn)]

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.Macro.matcher(spec, child_method)
      end
    )

    base_dependency = base_spec
    |> Map.delete("allOf")
    |> Exonerate.Macro.matcher(base_child)

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_all(
          __MODULE__,
          unquote(deps_list),
          [val],
          unquote(method))
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_anyof(map, list(any), atom) :: [defblock]
  def match_anyof(base_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    children_fn = &Method.concat(method, "_anyof_" <> inspect &1)
    base_child = Method.concat(method, "_allof_base")

    deps_list = Enum.map(idx_range, children_fn)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.Macro.matcher(spec, child_method)
      end
    )

    base_dependency = base_spec
    |> Map.delete("anyOf")
    |> Exonerate.Macro.matcher(base_child)

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_any(
          __MODULE__,
          unquote(deps_list),
          unquote(base_child),
          [val],
          unquote(method))
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_oneof(map, list(any), atom) :: [defblock]
  def match_oneof(_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    children_fn = &Method.concat(method, "_oneof_" <> inspect &1)

    deps_list = Enum.map(idx_range, children_fn)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        child_method = children_fn.(idx)
        Exonerate.Macro.matcher(spec, child_method)
      end
    )

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_one(
          __MODULE__,
          unquote(deps_list),
          [val],
          unquote(method))
      end
    end] ++ dependencies
  end

  @spec match_not(map, any, atom) :: [defblock]
  def match_not(_spec, inv_spec, method) do

    not_method = Method.concat(method, "_not")

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.apply_not(
          __MODULE__,
          unquote(not_method),
          [val])
      end
    end] ++ Exonerate.Macro.matcher(inv_spec, not_method)
  end
end
