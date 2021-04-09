defmodule Exonerate.Types.Number do
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [:minimum, :maximum, :exclusive_minimum, :exclusive_maximum]

  def build(method, params), do: %__MODULE__{
    method: method,
    minimum: params["minimum"],
    maximum: params["maximum"],
    exclusive_minimum: params["exclusive_minimum"],
    exclusive_maximum: params["exclusive_maximum"]
  }

  defimpl Exonerate.Buildable do
    def build(params = %{method: method}) do
      compare_branches =
        compare_branch(method, :<, params.minimum) ++
        compare_branch(method, :>, params.maximum) ++
        compare_branch(method, :<=, params.exclusive_minimum) ++
        compare_branch(method, :>=, params.exclusive_maximum)

      quote do
        defp unquote(method)(content, path) when not is_number(content) do
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
  end
end
