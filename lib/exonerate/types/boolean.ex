defmodule Exonerate.Types.Boolean do
  use Exonerate.Builder, []

  def build(schema, path) do
    build_generic(%__MODULE__{
      path: path
    }, schema)
    end

  defimpl Exonerate.Buildable do

    use Exonerate.GenericTools, [:filter_generic]

    def build(spec = %{path: spec_path}) do
      quote do
        defp unquote(spec_path)(value, path) when not is_boolean(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        unquote_splicing(filter_generic(spec))
        defp unquote(spec_path)(_value, _path), do: :ok
      end
    end
  end
end
