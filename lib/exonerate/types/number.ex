defmodule Exonerate.Types.Number do
  use Exonerate.Builder, ~w(
    minimum
    maximum
    exclusive_minimum
    exclusive_maximum
    multiple_of
  )a

  def build(schema, path) do
    build_generic(%__MODULE__{
      path: path,
      minimum: schema["minimum"],
      maximum: schema["maximum"],
      exclusive_minimum: schema["exclusiveMinimum"],
      exclusive_maximum: schema["exclusiveMaximum"],
      multiple_of: schema["multipleOf"]
    }, schema)
  end

  defimpl Exonerate.Buildable do

    use Exonerate.GenericTools, [:filter_generic]

    def build(spec = %{path: spec_path}) do
      compare_branches =
        compare_guard(spec_path, "minimum", spec.minimum) ++
        compare_guard(spec_path, "maximum", spec.maximum) ++
        compare_guard(spec_path, "exclusiveMinimum", spec.exclusive_minimum) ++
        compare_guard(spec_path, "exclusiveMaximum", spec.exclusive_maximum) ++
        multiple_guards(spec_path, spec.multiple_of)

      quote do
        defp unquote(spec_path)(value, path) when not is_number(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        unquote_splicing(filter_generic(spec))
        unquote_splicing(compare_branches)
        defp unquote(spec_path)(_value, _path), do: :ok
      end
    end

    @operands %{
      "minimum" => :<,
      "maximum" => :>,
      "exclusiveMinimum" => :<=,
      "exclusiveMaximum" => :>=
    }

    defp compare_guard(_, _, nil), do: []
    defp compare_guard(path, branch, limit) do
      compexpr = {@operands[branch], [], [quote do number end, limit]}
      [quote do
        defp unquote(path)(number, path) when unquote(compexpr) do
          Exonerate.Builder.mismatch(number, path, subpath: unquote(branch))
        end
      end]
    end

    defp multiple_guards(_, nil), do: []
    defp multiple_guards(path, limit) do
      [quote do
        defp unquote(path)(noninteger, path) when not is_integer(noninteger) do
          Exonerate.Builder.mismatch(integer, path, subpath: "multipleOf")
        end
        defp unquote(path)(integer, path) when rem(integer, unquote(limit)) != 0 do
          Exonerate.Builder.mismatch(integer, path, subpath: "multipleOf")
        end
      end]
    end
  end
end
