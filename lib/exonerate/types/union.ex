defmodule Exonerate.Types.Union do
  @enforce_keys [:method, :types]
  defstruct @enforce_keys

  def build(method, params) do
    types = params["type"]
    |> Enum.with_index
    |> Enum.map(&build_reenter(&1, method, params))

    %__MODULE__{
      method: method,
      types: types
    }
  end

  def build_reenter({type, index}, method, params), do:
    Exonerate.Builder.to_struct(%{params | "type" => type}, :"#{method}_#{index}")

  defimpl Exonerate.Buildable do
    def build(%{method: method, types: types}) do
      cond_branches = Enum.map(types, &cond_branch(&1.method)) ++ [
        arrow(true, {:mismatch, {v(:path), v(:json)}})]

      cond_body = {:cond, [], [[do: cond_branches]]}

      [{:defp, [],
      [
        {method, [], [v(:json), v(:path)]},
        [do: cond_body]
      ]}] ++ Enum.map(types, &Exonerate.Buildable.build(&1))
    end

    defp cond_branch(method) do
      arrow({:==, [], [{method, [], [v(:json), v(:path)]}, :ok]}, :ok)
    end

    defp arrow(left, right), do: {:->, [], [[left], right]}
    defp v(name), do: {name, [], Elixir}

  end
end
