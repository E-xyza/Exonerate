defmodule Exonerate.Id do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Tools
  alias Exonerate.Type

  @doc """
  walks through the schema and identifies places where ids are set.

  It then clones the subschema where the ids are, and then caches this
  as a separate entry under its own resource.
  """
  def prescan(schema, module, resource, opts) do
    root_resource =
      resource
      |> to_string
      |> URI.parse()

    resource_map =
      Tools.scan(
        schema,
        %{JsonPointer.from_path("/") => root_resource},
        &id_walk(module, &1, &2, &3, opts)
      )

    {schema, resource_map}
  end

  @type resource_map :: %{optional(JsonPointer.t()) => URI.t()}
  @spec id_walk(module, Type.json(), JsonPointer.t(), resource_map, keyword) :: resource_map

  defp id_walk(module, schema = %{"$id" => id}, pointer, resource_map, opts) do
    register(module, schema, id, pointer, resource_map, opts)
  end

  defp id_walk(module, schema = %{"id" => id}, pointer, resource_map, opts) do
    register(module, schema, id, pointer, resource_map, opts)
  end

  defp id_walk(_, _, _, acc, _), do: acc

  defp register(module, schema, id, pointer, resource_map, opts) do
    new_uri =
      case URI.parse(id) do
        # if we don't have any resource information, splice it into the existing resource.
        %{
          scheme: nil,
          userinfo: nil,
          host: nil,
          port: nil,
          path: path,
          query: query,
          fragment: _
        } ->
          {base, _} = find_resource_uri(resource_map, pointer)
          %{base | path: splice_path(base.path, path), query: query}

        new_uri ->
          new_uri
      end

    resource_uri = adjust_path(%{new_uri | fragment: nil})

    # we have to canonicalize this, because it's possible this content
    # is not reached from the main canonicalization effort.
    schema = Degeneracy.canonicalize(schema, opts)
    resource = :"#{resource_uri}"

    Cache.put_schema(module, resource, schema)

    Map.put(resource_map, pointer, resource_uri)
  end

  @spec find_resource_uri(resource_map, JsonPointer.t()) :: {URI.t(), JsonPointer.t()}
  @doc """
  given a resource map and pointer, find the resource that matches the jsonpointer.

  Note that resource map is a map of JsonPointer -> URI.

  This function proceeds by reveres induction over JsonPointer.  The execution time
  might be very bad, but this function should be called rarely.
  """
  def find_resource_uri(map, pointer) when is_map_key(map, pointer),
    do: {map[pointer], JsonPointer.from_path("/")}

  def find_resource_uri(map, pointer) do
    {prev, leaf} = JsonPointer.pop(pointer)
    {resource_uri, root} = find_resource_uri(map, prev)
    {resource_uri, JsonPointer.join(root, leaf)}
  end

  defp splice_path(nil, path), do: path
  defp splice_path(base, path), do: Path.join(base, path)

  defp adjust_path(uri = %{host: nil}), do: uri
  defp adjust_path(uri = %{path: "/" <> _}), do: uri
  defp adjust_path(uri = %{path: path}), do: %{uri | path: "/" <> path}
end
