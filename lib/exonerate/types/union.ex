defmodule Exonerate.Types.Union do
  use Exonerate.Builder, [:types]

  def build(params, path) do
    types = params["type"]
    |> Enum.with_index
    |> Enum.map(&spec_rebuild(&1, path, params))

    %__MODULE__{
      path: path,
      types: types
    }
  end

  def spec_rebuild({type, index}, path, params), do:
    Exonerate.Builder.to_struct(%{params | "type" => type}, :"#{path}/type/#{index}")

  defimpl Exonerate.Buildable do
    def build(%{path: spec_path, types: type_spec}) do

      {calls, helpers} = type_spec
      |> Enum.map(fn spec ->
        {
          quote do
            try do
              throw unquote(spec.path)(value, path)
            catch
              {:mismatch, _} -> :ok
            end
          end,
          Exonerate.Buildable.build(spec)
        }
      end)
      |> Enum.unzip

      quote do
        defp unquote(spec_path)(value, path) do
          unquote_splicing(calls)
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        catch
          :ok -> :ok
        end
        unquote_splicing(helpers)
      end
    end
  end
end
