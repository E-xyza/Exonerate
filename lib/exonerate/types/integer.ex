defmodule Exonerate.Types.Integer do
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
    end

    @operands %{
      "minimum" => :<,
      "maximum" => :>,
      "exclusiveMinimum" => :<=,
      "exclusiveMaximum" => :>=
    }

    defp compare_guard(_, _, nil), do: []
    defp compare_guard(path, branch, limit) do
      compexpr = {@operands[branch], [], [quote do integer end, limit]}
      [quote do
        defp unquote(path)(integer, path) when unquote(compexpr) do
          Exonerate.mismatch(integer, path, subpath: unquote(branch))
        end
      end]
    end

    defp multiple_guard(_, nil), do: []
    defp multiple_guard(path, limit) do
      [quote do
        defp unquote(path)(integer, path) when rem(integer, unquote(limit)) != 0 do
          Exonerate.mismatch(integer, path, subpath: "multipleOf")
        end
      end]
    end
  end
end
