defmodule Exonerate.Schema do
  @moduledoc false

  # module for ingesting JsonSchema data into the cache

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Id
  alias Exonerate.Tools
  alias Exonerate.Remote

  def ingest(binary, caller, resource, opts) do
    {caller.module, resource}

    binary
    |> Tools.decode!(opts)
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
    Tools.scan(
      schema,
      resource_map,
      &ref_walk(caller, &1, &2, &3, opts)
    )

    Cache.fetch_schema!(caller.module, resource)
  end

  defp ref_walk(caller, %{"$ref" => ref}, pointer, resource_map, opts) when is_binary(ref) do
    {ref_resource_uri, ref_pointer} = Id.find_resource_uri(resource_map, pointer)

    new_uri =
      ref_resource_uri
      |> Tools.uri_merge(URI.parse(ref))
      |> Remote.ensure_resource_loaded!(caller, opts)

    tgt_resource = Tools.uri_to_resource(new_uri)
    tgt_pointer = JsonPointer.from_path(new_uri.fragment)

    # next, update the cache to handle degeneracy
    Cache.update_schema!(
      caller.module,
      tgt_resource,
      tgt_pointer,
      &Degeneracy.canonicalize(&1, opts)
    )

    # update the ref registry with the current ref.
    Cache.register_ref(
      caller.module,
      Tools.uri_to_resource(ref_resource_uri),
      ref_pointer,
      tgt_resource,
      tgt_pointer
    )

    resource_map
  end

  defp ref_walk(_, _, _, resource_map, _), do: resource_map
end
