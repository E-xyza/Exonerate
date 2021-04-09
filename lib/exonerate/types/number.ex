defmodule Exonerate.Types.Number do
  @enforce_keys [:path]
  defstruct @enforce_keys ++ [:minimum, :maximum, :exclusive_minimum, :exclusive_maximum]

  def build(schema, path), do: %__MODULE__{
    path: path,
    minimum: schema["minimum"],
    maximum: schema["maximum"],
    exclusive_minimum: schema["exclusive_minimum"],
    exclusive_maximum: schema["exclusive_maximum"]
  }

  defimpl Exonerate.Buildable do
    def build(schema = %{path: schema_path}) do
      compare_branches =
        compare_branch(schema_path, "minimum", schema.minimum) ++
        compare_branch(schema_path, "maximum", schema.maximum) ++
        compare_branch(schema_path, "exclusive_minimum", schema.exclusive_minimum) ++
        compare_branch(schema_path, "exclusive_maximum", schema.exclusive_maximum)

      quote do
        defp unquote(schema_path)(value, path) when not is_number(content) do
          Exonerate.Builder.mismatch(value, path)
        end
        unquote_splicing(compare_branches)
        defp unquote(schema_path)(content, path), do: :ok
      end
    end

    @operands %{
      "minimum" => :<,
      "maximum" => :>,
      "exclusive_minimum" => :<=,
      "exclusive_maximum" => :>=
    }

    defp compare_branch(_, _, nil), do: []
    defp compare_branch(path, branch, limit) do
      compexpr = {@operands[branch], [], [quote do value end, limit]}
      [quote do
        defp unquote(path)(number, path) when unquote(compexpr) do
          Exonerate.Builder.mismatch(number, path, subpath: unquote(branch))
        end
      end]
    end
  end
end
