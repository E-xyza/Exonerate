defmodule Exonerate.Types.String do
  use Exonerate.Builder, ~w(pattern min_length max_length)a
  def build(schema, path) do
    build_generic(%__MODULE__{
      path: path,
      pattern: schema["pattern"],
      min_length: schema["minLength"],
      max_length: schema["maxLength"]}, schema)
    end

  defimpl Exonerate.Buildable do

    use Exonerate.GenericTools, [:filter_generic]

    def build(spec = %{path: spec_path}) do
      uses_length = if spec.min_length || spec.max_length do
        quote do length = String.length(value) end
      end

      min_length = if min = spec.min_length do
        quote do
          (length < unquote(min)) && Exonerate.mismatch(value, path, subpath: "minLength")
        end
      end
      max_length = if max = spec.max_length do
        quote do
          (length > unquote(max)) && Exonerate.mismatch(value, path, subpath: "maxLength")
        end
      end

      quote do
        defp unquote(spec_path)(value, path) when not is_binary(value) do
          Exonerate.mismatch(value, path, subpath: "type")
        end
        unquote_splicing(filter_generic(spec))
        defp unquote(spec_path)(value, path) do
          unquote(uses_length)
          unquote(min_length)
          unquote(max_length)
          unquote(pattern_call(spec))
        end
        unquote_splicing(pattern_filter(spec))
      end
    end

    defp pattern_call(%{pattern: nil}), do: :ok
    defp pattern_call(spec) do
      pattern_filter = Exonerate.join(spec.path, "pattern")
      quote do
        unquote(pattern_filter)(value, path)
      end
    end

    defp pattern_filter(%{pattern: nil}), do: []
    defp pattern_filter(spec) do
      pattern_filter = Exonerate.join(spec.path, "pattern")
      [quote do
        def unquote(pattern_filter)(value, path) do
          if value =~ sigil_r(<<unquote(spec.pattern)>>, []) do
            :ok
          else
            Exonerate.mismatch(value, path)
          end
        end
      end]
    end
  end
end
