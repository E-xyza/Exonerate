defmodule Exonerate.Builder do
  @moduledoc false

  def build(full_json_spec, method, opts) do
    full_json_spec
    |> traverse_path(opts)
    |> to_struct(method)
  end

  # temporary
  defp traverse_path(json_spec, _), do: json_spec

  @empty_map %{}

  def to_struct(params = %{"type" => "object"}, method) do
    Exonerate.Types.Object.build(method, params)
  end
  def to_struct(params = %{"type" => "number"}, method) do
    to_struct(%{params | "type" => ["float", "integer"]}, method)
  end
  def to_struct(params = %{"type" => "float"}, method) do
    Exonerate.Types.Float.build(method, params)
  end
  def to_struct(params = %{"type" => "integer"}, method) do
    Exonerate.Types.Integer.build(method, params)
  end
  def to_struct(params = %{"type" => "string"}, method) do
    Exonerate.Types.String.build(method, params)
  end
  def to_struct(params = %{"type" => "list"}, method) do
    Exonerate.Types.List.build(method, params)
  end
  def to_struct(params = %{"type" => list}, method) when is_list(list) do
    Exonerate.Types.Union.build(method, params)
  end
  def to_struct(@empty_map, method) do
    Exonerate.Types.Absolute.build(method)
  end
  def to_struct(true, method) do
    Exonerate.Types.Absolute.build(method)
  end
  def to_struct(false, method) do
    Exonerate.Types.Absolute.build(method, accept: false)
  end
end
