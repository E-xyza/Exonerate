defmodule Exonerate.Types.String do
  @enforce_keys [:path]
  @props ~w(pattern min_length max_length)a
  defstruct @enforce_keys ++ @props

  def build(schema, path), do: %__MODULE__{
    path: path,
    pattern: schema["pattern"],
    min_length: schema["minLength"],
    max_length: schema["maxLength"]}

  defimpl Exonerate.Buildable do
    alias Exonerate.Types.String

    def build(%{path: spec_path}) do
      quote do
        defp unquote(spec_path)(value, path) when not is_binary(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        defp unquote(spec_path)(_, _) do
          :ok
        end
      end
    end

    defp filter_condition(:pattern, pattern) do
      quote do content =~ sigil_r(<<unquote(pattern)>>, []) end
    end

    defp filter_condition(:min_length, length) do
      quote do String.length(content) >= unquote(length) end
    end

    defp filter_condition(:max_length, length) do
      quote do String.length(content) <= unquote(length) end
    end
  end
end
