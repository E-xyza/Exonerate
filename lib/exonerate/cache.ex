defmodule Exonerate.Cache do
  @moduledoc false

  # registry for existing registry paths.  Since each module is compiled by a
  # single process, let's tie the registry information to the lifetime of the
  # module compilation.  This is done by spinning up an ets table that stores
  # information as to the state of the registry path, its schema, and its
  # pointer.  Thus multiple entrypoints using the same schema can share
  # validation functions.

  alias Exonerate.Tools
  alias Exonerate.Type

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

  @spec get(atom | {:file, Path.t()}) :: {:ok, Type.json()} | :error
  def get(cache_id) do
    case :ets.lookup(get_table(), cache_id) do
      [] -> :error
      [{:cached, id}] when is_atom(id) -> get(id)
      [{^cache_id, json}] -> {:ok, json}
    end
  end

  @spec put(atom | {:file, Path.t(), atom}, Type.json()) :: :ok
  def put({:file, path, authority}, content) do
    info = [
      {{:file, path}, {:cached, authority}},
      {authority, content}
    ]

    :ets.insert(get_table(), info)
    :ok
  end

  def put(authority, content) when is_atom(authority) do
    :ets.insert(get_table(), {authority, content})
    :ok
  end

  @doc false
  # if you are doing something single-threaded (like compiling multiple modules in a test), you might need to do this.
  def sweep do
    if table = Process.get(__MODULE__) do
      :ets.delete(table)
      Process.delete(__MODULE__)
    end
  end
end
