defmodule Exonerate.Types.Integer do
  @enforce_keys [:path]
  defstruct @enforce_keys ++ [:minimum, :maximum, :exclusive_minimum, :exclusive_maximum, :multiple_of]

  def build(path, params), do: %__MODULE__{
    path: path,
    minimum: params["minimum"],
    maximum: params["maximum"],
    exclusive_minimum: params["exclusiveMinimum"],
    exclusive_maximum: params["exclusiveMaximum"],
    multiple_of: params["multipleOf"]
  }

  defimpl Exonerate.Buildable do
    def build(params = %{path: path}) do
      compare_branches =
        compare_branch(path, :<, params.minimum) ++
        compare_branch(path, :>, params.maximum) ++
        compare_branch(path, :<=, params.exclusive_minimum) ++
        compare_branch(path, :>=, params.exclusive_maximum) ++
        multiple_branch(path, params.multiple_of)

      quote do
        defp unquote(path)(content, path) when not is_integer(content) do
          {:mismatch, {path, content}}
        end
        unquote_splicing(compare_branches)
        defp unquote(path)(content, path), do: :ok
      end
    end

    defp compare_branch(_, _, nil), do: []
    defp compare_branch(path, op, limit) do
      compexpr = {op, [], [quote do value end, limit]}
      [quote do
        defp unquote(path)(value, path) when unquote(compexpr) do
          {:mismatch, {path, value}}
        end
      end]
    end

    defp multiple_branch(_, nil), do: []
    defp multiple_branch(path, factor) do
      [quote do
        defp unquote(path)(value, path) when rem(value, unquote(factor)) != 0 do
          {:mismatch, {path, value}}
        end
      end]
    end
  end
end
