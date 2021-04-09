defmodule Exonerate.Types.Union do
  @enforce_keys [:path, :types]
  defstruct @enforce_keys

  def build(path, params) do
    types = params["type"]
    |> Enum.with_index
    |> Enum.map(&build_reenter(&1, path, params))

    %__MODULE__{
      path: path,
      types: types
    }
  end

  def build_reenter({type, index}, path, params), do:
    Exonerate.Builder.to_struct(%{params | "type" => type}, :"#{path}_#{index}")

  defimpl Exonerate.Buildable do
    def build(%{path: path, types: types}) do
      calls = Enum.map(types, &quote do
        unless (error = unquote(&1.path)(value, path)) == :ok do
          throw error
        end
      end)

      helpers = Enum.map(types, &Exonerate.Buildable.build(&1))

      quote do
        defp unquote(path)(value, path) do
          unquote_splicing(calls)
        catch
          error = {:mismatch, _} -> error
        end

        unquote_splicing(helpers)
      end
    end
  end
end
