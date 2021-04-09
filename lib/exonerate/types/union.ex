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
      calls = Enum.map(types, &quote do
        unless (error = unquote(&1.method)(value, path)) == :ok do
          throw error
        end
      end)

      helpers = Enum.map(types, &Exonerate.Buildable.build(&1))

      quote do
        defp unquote(method)(value, path) do
          unquote_splicing(calls)
        catch
          error = {:mismatch, _} -> error
        end

        unquote_splicing(helpers)
      end
    end
  end
end
