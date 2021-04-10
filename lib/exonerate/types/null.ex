defmodule Exonerate.Types.Null do
  use Exonerate.Builder, []

  def build(_schema, path), do: %__MODULE__{
    path: path
  }

  defimpl Exonerate.Buildable do
    def build(%{path: spec_path}) do
      quote do
        defp unquote(spec_path)(value, path) when not is_nil(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        defp unquote(spec_path)(_value, _path), do: :ok
      end
    end
  end
end
