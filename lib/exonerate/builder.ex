defmodule Exonerate.Builder do
  @moduledoc false

  defmacro __using__(fields) do
    quote do
      @enforce_keys [:path]
      @common_keys [:enum, :const]
      defstruct @enforce_keys ++ @common_keys ++ unquote(fields)

      import Exonerate.Builder, only: [build_generic: 2]
    end
  end

  def build(full_json_spec, path, opts) do
    full_json_spec
    |> traverse_path(opts)
    |> to_struct(path)
  end

  # temporary
  defp traverse_path(json_spec, _), do: json_spec

  def to_struct(spec = %{"type" => "object"}, path) do
    Exonerate.Types.Object.build(spec, path)
  end
  def to_struct(spec = %{"type" => "number"}, path) do
    Exonerate.Types.Number.build(spec, path)
  end
  def to_struct(spec = %{"type" => "integer"}, path) do
    Exonerate.Types.Integer.build(spec, path)
  end
  def to_struct(spec = %{"type" => "string"}, path) do
    Exonerate.Types.String.build(spec, path)
  end
  def to_struct(spec = %{"type" => "array"}, path) do
    Exonerate.Types.Array.build(spec, path)
  end
  def to_struct(spec = %{"type" => "boolean"}, path) do
    Exonerate.Types.Boolean.build(spec, path)
  end
  def to_struct(spec = %{"type" => "null"}, path) do
    Exonerate.Types.Null.build(spec, path)
  end
  def to_struct(spec = %{"type" => list}, path) when is_list(list) do
    Exonerate.Types.Union.build(spec, path)
  end
  def to_struct(%{"type" => type}, path) do
    raise CompileError, message: "invalid type #{inspect type} found at #{path}"
  end
  def to_struct(spec, path) when is_map(spec) do
    spec
    |> Map.put("type", ~w(object number integer string array boolean null))
    |> Exonerate.Types.Union.build(path)
  end
  def to_struct(true, path) do
    Exonerate.Types.Absolute.build(%{"accept" => true}, path)
  end
  def to_struct(false, path) do
    Exonerate.Types.Absolute.build(%{"accept" => false}, path)
  end

  def build_generic(s, spec) do
    struct(s, enum: spec["enum"], const: spec["const"])
  end
end
