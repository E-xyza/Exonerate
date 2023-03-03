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

  @type cache_id :: atom | {:file, Path.t()}

  @spec fetch_schema(module, cache_id) :: {:ok, Type.json()} | :error
  def fetch_schema(module, cache_id) do
    case :ets.lookup(get_table(), {module, cache_id}) do
      [] -> :error
      [{{^module, ^cache_id}, {:cached, id}}] when is_atom(id) -> fetch_schema(module, id)
      [{{^module, ^cache_id}, json}] -> {:ok, json}
    end
  end

  @spec fetch_schema!(module, cache_id) :: Type.json()
  def fetch_schema!(module, cache_id) do
    case fetch_schema(module, cache_id) do
      {:ok, json} ->
        json

      :error ->
        raise KeyError,
          message:
            "key `#{cache_id}` not found in the exonerate cache for the module #{inspect(module)}"
    end
  end

  @spec put_schema(module, authority :: atom, schema :: Type.json()) :: :ok
  def put_schema(module, authority, content) when is_atom(authority) do
    :ets.insert(get_table(), {{module, authority}, content})
    :ok
  end

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

  def register_id(id, module, pointer) do
    :ets.insert(get_table(), {{:id, id, module}, pointer})
  end

  defmatchspecp get_id_ms(id, module) do
    {{:id, ^id, ^module}, pointer} -> pointer
  end

  def get_id(id, module) do
    case :ets.select(get_table(), get_id_ms(id, module)) do
      [] -> nil
      [pointer] -> pointer
    end
  end
end
