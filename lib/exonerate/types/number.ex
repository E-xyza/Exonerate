defmodule Exonerate.Types.Number do
  @enforce_keys [:path]
  defstruct @enforce_keys ++ [:minimum, :maximum, :exclusive_minimum, :exclusive_maximum, :multiple_of]

  def build(spec, path), do: %__MODULE__{
    path: path,
    minimum: spec["minimum"],
    maximum: spec["maximum"],
    exclusive_minimum: spec["exclusiveMinimum"],
    exclusive_maximum: spec["exclusiveMaximum"],
    multiple_of: spec["multipleOf"]
  }

  defimpl Exonerate.Buildable do
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
