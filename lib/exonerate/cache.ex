defmodule Exonerate.Cache do
  @moduledoc false

  # registry for existing registry paths.  Since each module is compiled by a
  # single process, let's tie the registry information to the lifetime of the
  # module compilation.  This is done by spinning up an ets table that stores
  # information as to the state of the registry path, its schema, and its
  # pointer.  Thus multiple entrypoints using the same schema can share
  # validation functions.

  alias Exonerate.Type
  use MatchSpec

  @spec get_table() :: :ets.tid()
  def get_table do
    if tid = Process.get(__MODULE__) do
      tid
    else
      tid = :ets.new(__MODULE__, [:set, :private])
      Process.put(__MODULE__, tid)
      tid
    end
  end

  defmodule Resource do
    @moduledoc false
    defstruct [:uri, :sha, :schema, :opts]

    @type t :: %__MODULE__{
            uri: URI.t(),
            sha: String.t(),
            schema: String.t(),
            opts: keyword
          }
  end

  # RESOURCES
  @resource_opts ~w(encoding mimetype_mapping decoders)a

  defmatchspecp get_res_ms(module, name) do
    {{:resource, ^module, ^name}, resource} -> resource
  end

  defp hash(schema, opts) do
    opts =
      opts
      |> Keyword.take(@resource_opts)
      |> Enum.sort()

    :sha256
    |> :crypto.hash(:erlang.term_to_binary({schema, opts}))
    |> Base.encode16()
  end

  @spec register_resource(module, schema :: Type.json(), name :: String.t(), keyword) ::
          Resource.t()
  def register_resource(module, schema, name, opts) do
    opts = Keyword.take(opts, @resource_opts)
    hash = hash(schema, opts)

    resource = %Resource{
      uri: URI.parse("exonerate://#{hash}/"),
      sha: hash,
      schema: schema,
      opts: opts
    }

    :ets.insert(get_table(), {{:resource, module, name}, resource})
    resource
  end

  @spec fetch_resource(module, name :: String.t()) :: {:ok, Resource.t()} | :error
  def fetch_resource(module, name) do
    case :ets.select(get_table(), get_res_ms(module, name)) do
      [] -> :error
      [resource] -> {:ok, resource}
    end
  end

  @spec fetch_resource!(module, name :: String.t()) :: Resource.t()
  def fetch_resource!(module, name) do
    case fetch_resource(module, name) do
      :error -> raise KeyError, message: "resource named #{name} not found in cache"
      {:ok, resource} -> resource
    end
  end

  defmatchspecp find_res_ms(module, hash) do
    {{:resource, ^module, _}, resource} when resource.hash === hash -> resource
  end

  @spec find_resource(module, schema :: String.t(), keyword) :: :error | {:ok, Resource.t()}
  def find_resource(module, schema, opts) do
    opts = Keyword.take(opts, @resource_opts)
    hash = hash(schema, opts)

    case :ets.select(get_table(), find_res_ms(module, hash)) do
      [] -> :error
      [resource] -> {:ok, resource}
    end
  end

  @spec find_or_make_resource(module, schema :: String.t(), name :: String.t() | nil, keyword) ::
          Resource.t()
  def find_or_make_resource(module, schema, name \\ nil, opts) do
    name = name || hash(schema, opts)

    case find_resource(module, schema, opts) do
      :error ->
        register_resource(module, schema, name, opts)

      {:ok, resource} ->
        resource
    end
  end

  # SCHEMAS
  @type resource_uri :: String.t()

  @spec fetch_schema(module, resource_uri) :: {:ok, Type.json()} | :error
  def fetch_schema(module, resource_uri) do
    case :ets.lookup(get_table(), {module, resource_uri}) do
      [] -> :error
      [{{^module, ^resource_uri}, {:cached, id}}] when is_binary(id) -> fetch_schema(module, id)
      [{{^module, ^resource_uri}, json}] -> {:ok, json}
    end
  end

  @spec fetch_schema!(module, resource_uri) :: Type.json()
  def fetch_schema!(module, resource_uri) do
    case fetch_schema(module, resource_uri) do
      {:ok, json} ->
        json

      :error ->
        raise KeyError,
          message:
            "key `#{resource_uri}` not found in the exonerate cache for the module #{inspect(module)}"
    end
  end

  @spec put_schema(module, resource_uri :: String.t(), schema :: Type.json()) :: :ok
  def put_schema(module, resource_uri, schema) do
    :ets.insert(get_table(), {{module, resource_uri}, schema})
    :ok
  end

  @spec update_schema!(
          module,
          resource_uri :: String.t(),
          JsonPtr.t(),
          (Type.json() -> Type.json())
        ) ::
          :ok
  def update_schema!(module, resource_uri, pointer, transformation) do
    new_schema =
      module
      |> fetch_schema!(resource_uri)
      |> JsonPtr.update_json!(pointer, transformation)

    put_schema(module, resource_uri, new_schema)

    :ok
  rescue
    KeyError ->
      raise CompileError,
        description:
          "reference points to: #{JsonPtr.to_uri(pointer)}, this location not found in the schema"
  end

  @spec has_schema?(module, resource_uri :: String.t()) :: boolean
  def has_schema?(module, resource_uri) do
    case :ets.lookup(get_table(), {module, resource_uri}) do
      [] -> false
      [_] -> true
    end
  end

  # REFERENCES

  defmatchspecp get_ref_ms(module, ref_resource, ref_pointer) do
    {{:ref, {^module, ^ref_resource, ^ref_pointer}}, {^module, tgt_resource, tgt_pointer}} ->
      {tgt_resource, tgt_pointer}
  end

  defmatchspecp get_ref_pointers_ms(module, tgt_resource) do
    {{:ref, {^module, ^tgt_resource, _}}, {^module, ^tgt_resource, tgt_pointer}} -> tgt_pointer
  end

  def register_ref(module, ref_resource, ref_pointer, tgt_resource, tgt_pointer) do
    :ets.insert(
      get_table(),
      {{:ref, {module, ref_resource, ref_pointer}}, {module, tgt_resource, tgt_pointer}}
    )

    :ok
  end

  def traverse_ref!(module, ref_resource, ref_pointer) do
    case :ets.select(get_table(), get_ref_ms(module, ref_resource, ref_pointer)) do
      [] -> raise "ref at #{JsonPtr.to_uri(ref_pointer)} not found"
      [ref] -> ref
    end
  end

  def all_ref_pointers(module, ref_resource) do
    get_table()
    |> :ets.select(get_ref_pointers_ms(module, ref_resource))
    |> MapSet.new()
  end

  # CONTEXTS

  def register_context(module, call) when is_atom(call) do
    if has_context?(module, call) do
      false
    else
      :ets.insert(get_table(), {{:context, module, call}})
      true
    end
  end

  def has_context?(module, call) when is_atom(call) do
    case :ets.lookup(get_table(), {:context, module, call}) do
      [] -> false
      [_] -> true
    end
  end

  @all MatchSpec.fun2ms(fn any -> any end)
  def dump do
    :ets.select(get_table(), @all)
  end

  @refs MatchSpec.fun2ms(fn result = {{:ref, _}, _} -> result end)
  def dump(:refs) do
    :ets.select(get_table(), @refs)
  end
end
