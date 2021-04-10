defmodule Exonerate.Types.Union do
  use Exonerate.Builder, [:types]

  def build(schema, path) do
    types = schema["type"]
    |> Enum.with_index
    |> Enum.map(&spec_rebuild(&1, path, schema))

    build_generic(%__MODULE__{
      path: path,
      types: types
    }, schema)
  end

  def spec_rebuild({type, index}, path, schema), do:
    Exonerate.Builder.to_struct(%{schema | "type" => type}, :"#{path}/type/#{index}")

  defimpl Exonerate.Buildable do

    use Exonerate.GenericTools, [:filter_generic]

    def build(spec = %{path: spec_path, types: type_spec}) do

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
        unquote_splicing(filter_generic(spec))
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
