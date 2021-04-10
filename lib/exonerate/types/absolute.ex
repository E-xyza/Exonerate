defmodule Exonerate.Types.Absolute do
  use Exonerate.Builder, [:accept]

  def build(schema, path) do
    build_generic(
    %__MODULE__{
      path: path,
      accept: Map.get(schema, "accept", true)
    }, schema)
  end

  defimpl Exonerate.Buildable do

    use Exonerate.GenericTools, [:filter_generic]

    def build(spec = %{accept: true}) do
      quote do
        unquote_splicing(filter_generic(spec))
        defp unquote(spec.path)(_, _), do: :ok
      end
    end

    def build(spec = %{accept: false}) do
      quote do
        defp unquote(spec.path)(value, path) do
          Exonerate.Builder.mismatch(value, path)
        end
      end
    end
  end
end
