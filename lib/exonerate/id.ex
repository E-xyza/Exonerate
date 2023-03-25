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
          base = find_resource(resource_map, pointer)
          %{base | path: path, query: query}

        new_uri ->
          new_uri
      end

    resource = %{new_uri | fragment: nil}

    # we have to canonicalize this, because it's possible this content
    # is not reached from the main canonicalization effort.
    schema = Degeneracy.canonicalize(schema, opts)

    Cache.put_schema(module, :"#{resource}", schema)

    Map.put(resource_map, pointer, resource)
  end

  @spec find_resource(resource_map, JsonPointer.t()) :: URI.t()

  def find_resource(map, pointer) when is_map_key(map, pointer), do: map[pointer]

  def find_resource(map, pointer), do: find_resource(map, JsonPointer.backtrack!(pointer))
end
