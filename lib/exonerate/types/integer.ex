defmodule Exonerate.Types.Integer do
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [:minimum, :maximum, :exclusive_minimum, :exclusive_maximum, :multiple_of]

  def build(method, params), do: %__MODULE__{
    method: method,
    minimum: params["minimum"],
    maximum: params["maximum"],
    exclusive_minimum: params["exclusiveMinimum"],
    exclusive_maximum: params["exclusiveMaximum"],
    multiple_of: params["multipleOf"]
  }

  defimpl Exonerate.Buildable do
    def build(params = %{method: method}) do
      compare_branches =
        compare_branch(method, :<, params.minimum) ++
        compare_branch(method, :>, params.maximum) ++
        compare_branch(method, :<=, params.exclusive_minimum) ++
        compare_branch(method, :>=, params.exclusive_maximum) ++
        multiple_branch(method, params.multiple_of)

      quote do
        defp unquote(method)(content, path) when not is_integer(content) do
          {:mismatch, {path, content}}
        end
        unquote_splicing(compare_branches)
        defp unquote(method)(content, path), do: :ok
      end
    end

    defp compare_branch(_, _, nil), do: []
    defp compare_branch(method, op, limit) do
      compexpr = {op, [], [quote do value end, limit]}
      [quote do
        defp unquote(method)(value, path) when unquote(compexpr) do
          {:mismatch, {path, value}}
        end
      end]
    end

    defp multiple_branch(_, nil), do: []
    defp multiple_branch(method, factor) do
      [quote do
        defp unquote(method)(value, path) when rem(value, unquote(factor)) != 0 do
          {:mismatch, {path, value}}
        end
      end]
    end
  end
end
