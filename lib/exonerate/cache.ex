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

  @type resource :: atom | {:file, Path.t()}

  # SCHEMAS

  @spec fetch_schema(module, resource) :: {:ok, Type.json()} | :error
  def fetch_schema(module, resource) do
    case :ets.lookup(get_table(), {module, resource}) do
      [] -> :error
      [{{^module, ^resource}, {:cached, id}}] when is_binary(id) -> fetch_schema(module, id)
      [{{^module, ^resource}, json}] -> {:ok, json}
    end
  end

  @spec fetch_schema!(module, resource) :: Type.json()
  def fetch_schema!(module, resource) do
    case fetch_schema(module, resource) do
      {:ok, json} ->
        json

      :error ->
        raise KeyError,
          message:
            "key `#{resource}` not found in the exonerate cache for the module #{inspect(module)}"
    end
  end

  @spec put_schema(module, resource :: atom, schema :: Type.json()) :: :ok
  def put_schema(module, resource, schema) do
    :ets.insert(get_table(), {{module, resource}, schema})
    :ok
  end

  @spec update_schema!(module, resource :: atom, JsonPointer.t(), (Type.json() -> Type.json())) ::
          :ok
  def update_schema!(module, resource, pointer, transformation) do
    new_schema =
      module
      |> fetch_schema!(resource)
      |> JsonPointer.update_json!(pointer, transformation)

    put_schema(module, resource, new_schema)

    :ok
  end

  @spec has_schema?(module, resource :: atom) :: boolean
  def has_schema?(module, resource) do
    case :ets.lookup(get_table(), {module, resource}) do
      [] -> false
      [_] -> true
    end
  end

  # REFERENCES

  defmatchspecp get_ref_ms(module, ref_resource, ref_pointer) do
    {{:ref, {^module, ^ref_resource, ^ref_pointer}}, {^module, tgt_resource, tgt_pointer}} ->
      {tgt_resource, tgt_pointer}
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
      [] -> raise "ref not found"
      [ref] -> ref
    end
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

  require MatchSpec
  @all MatchSpec.fun2ms(fn any -> any end)
  def dump do
    :ets.select(get_table(), @all)
  end

  @refs MatchSpec.fun2ms(fn result = {{:ref, _}, _} -> result end)
  def dump(:refs) do
    :ets.select(get_table(), @refs)
  end
end
