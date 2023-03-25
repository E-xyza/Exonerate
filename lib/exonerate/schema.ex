defmodule Exonerate.Schema do
  @moduledoc false

  # module for ingesting JsonSchema data into the cache

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Id
  alias Exonerate.Tools

  def ingest(binary, caller, resource, opts) do
    {caller.module, resource}

    binary
    |> Jason.decode!()
    |> Degeneracy.canonicalize(opts)
    |> tap(&Cache.put_schema(caller.module, resource, &1))
    |> Id.prescan(caller.module, resource, opts)
    |> ref_prescan(caller, resource, opts)
  end

  @doc """
  walks through the schema and identifies places where the the refs need to be
  canonicalized, as well as annotating in the cache every place where refs need
  to be remembered.
  """
  def ref_prescan({schema, resource_map}, caller, resource, opts) do
    root_resource =
      resource
      |> to_string
      |> URI.parse()

    Tools.scan(
      schema,
      resource_map,
      &ref_walk(caller, &1, &2, &3, opts)
    )

    Cache.fetch_schema!(caller.module, resource)
  end

  defp ref_walk(caller, %{"$ref" => ref}, pointer, resource_map, opts) do
    uri = URI.parse(ref)

    {resource, pointer} =
      case uri do
        # path query, fragment only
        %{
          scheme: nil,
          userinfo: nil,
          host: nil,
          port: nil,
          path: path,
          query: query,
          fragment: fragment
        } ->
          resource =
            resource_map
            |> Id.find_resource(pointer)
            |> Tools.if(path || query, &Map.merge(&1, %{path: path, query: query}))
            |> Map.merge(%{fragment: fragment})
            |> Tools.uri_to_resource()

          {resource, JsonPointer.from_path(fragment)}

        # full uri
        uri = %{fragment: fragment} ->
          Remote.ensure_resource_loaded!(caller, uri, opts)
          {Tools.uri_to_resource(uri), JsonPointer.from_path(fragment)}
      end

    # next, update the cache to handle degeneracy
    Cache.update_schema!(caller.module, resource, pointer, &Degeneracy.canonicalize(&1, opts))

    resource_map
  end

  defp ref_walk(_, _, _, resource_map, _), do: resource_map
end
