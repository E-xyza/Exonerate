defmodule Exonerate.Types.Null do
  use Exonerate.Builder, []

  def build(_schema, path), do: %__MODULE__{
    path: path
  }

  defimpl Exonerate.Buildable do
    def build(%{path: spec_path}) do
      quote do
        defp unquote(spec_path)(value, _path) when is_nil(value), do: :ok
        defp unquote(spec_path)(value, path) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
      end
    end
  end
end
