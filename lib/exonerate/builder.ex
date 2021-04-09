defmodule Exonerate.Builder do
  @moduledoc false

  def build(full_json_spec, path, opts) do
    full_json_spec
    |> traverse_path(opts)
    |> to_struct(path)
  end

  # temporary
  defp traverse_path(json_spec, _), do: json_spec

  def to_struct(spec = %{"type" => "object"}, path) do
    Exonerate.Types.Object.build(spec, :"#{path}#")
  end
  def to_struct(spec = %{"type" => "number"}, path) do
    Exonerate.Types.Number.build(spec, :"#{path}#")
  end
  def to_struct(spec = %{"type" => "integer"}, path) do
    Exonerate.Types.Integer.build(spec, :"#{path}#")
  end
  def to_struct(spec = %{"type" => "string"}, path) do
    Exonerate.Types.String.build(spec, :"#{path}#")
  end
  def to_struct(spec = %{"type" => "array"}, path) do
    Exonerate.Types.Array.build(spec, :"#{path}#")
  end
  def to_struct(spec = %{"type" => list}, path) when is_list(list) do
    Exonerate.Types.Union.build(spec, :"#{path}#")
  end
  def to_struct(%{}, path) do
    Exonerate.Types.Absolute.build(:"#{path}#")
  end
  def to_struct(true, path) do
    Exonerate.Types.Absolute.build(:"#{path}#")
  end
  def to_struct(false, path) do
    Exonerate.Types.Absolute.build(false, :"#{path}#")
  end

  # helper function
  defmacro mismatch(value, path, opts \\ []) do
    schema_path = __CALLER__.function
    |> elem(0)
    |> to_string
    |> join(opts[:subpath] || "")

    quote do
      throw {:mismatch,
      schema_path: unquote(schema_path),
      error_value: unquote(value),
      json_path: unquote(path)}
    end
  end

  @spec join(atom, String.t) :: atom
  @spec join(Path.t, String.t) :: Path.t

  def join(path, subpath) when is_atom(path) do
    path
    |> Atom.to_string
    |> join(subpath)
    |> String.to_atom
  end
  def join(path, subpath) do
    if String.ends_with?(path, "#") do
      path <> subpath
    else
      Path.join(path, subpath)
    end
  end

end
