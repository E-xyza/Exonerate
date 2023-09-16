defmodule Exonerate.Schema do
  @moduledoc false

  # module for ingesting JsonSchema data into the cache

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Draft
  alias Exonerate.Id
  alias Exonerate.Tools
  alias Exonerate.Remote

  def ingest(binary, caller, resource, opts) do
    json_decoded = Tools.decode!(binary, opts)
    opts = Draft.set_opts(opts, json_decoded)

    json_decoded
    |> Degeneracy.canonicalize(opts)
    |> tap(&Cache.put_schema(caller.module, resource, &1))
    |> cache_assignments(caller, resource, opts)
  end

  defp cache_assignments(schema, caller, resource, opts, seen \\ MapSet.new()) do
    schema
    |> Id.prescan(caller.module, resource, opts)
    |> ref_prescan(caller, resource, opts)

    # recursively jump into references and go ahead run cache assignments on them.
    caller.module
    |> Cache.all_ref_pointers(resource)
    |> Enum.reject(&(&1 in seen))
    |> Enum.reduce(seen, fn pointer, seen_so_far ->
      new_seen = MapSet.put(seen_so_far, pointer)
      new_opts = Keyword.replace(opts, :entrypoint, JsonPtr.to_path(pointer))
      cache_assignments(schema, caller, resource, new_opts, new_seen)
      Cache.all_ref_pointers(caller.module, resource)
    end)

    schema
  end

  @doc """
  walks through the schema and identifies places where the the refs need to be
  canonicalized, as well as annotating in the cache every place where refs need
  to be remembered.
  """
  def ref_prescan({schema, resource_map}, caller, resource, opts) do
    entrypoint = get_entrypoint(opts)

    schema
    |> JsonPtr.resolve_json!(entrypoint)
    |> Tools.scan(
      resource_map,
      &ref_walk(caller, &1, &2, &3, opts)
    )

    Cache.fetch_schema!(caller.module, resource)
  end

  defp ref_walk(caller, %{"$ref" => ref}, pointer, resource_map, opts) when is_binary(ref) do
    resolved_pointer = JsonPtr.join(get_entrypoint(opts), pointer)

    {ref_resource_uri, ref_pointer} = Id.find_resource_uri(resource_map, resolved_pointer)

    new_uri =
      ref_resource_uri
      |> Tools.uri_merge(URI.parse(ref))
      |> Remote.ensure_resource_loaded!(caller, opts)

    tgt_resource = Tools.uri_to_resource(new_uri)
    tgt_pointer = JsonPtr.from_path(new_uri.fragment)

    # next, update the cache to handle degeneracy
    Cache.update_schema!(
      caller.module,
      tgt_resource,
      tgt_pointer,
      &Degeneracy.canonicalize(&1, Keyword.delete(opts, :entrypoint))
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

  defp get_entrypoint(opts) do
    opts
    |> Keyword.get(:entrypoint, "/")
    |> JsonPtr.from_path()
  end
end
