defmodule Exonerate.Registry do
  @moduledoc false

  # registry for existing registry paths.  Since each module is compiled by a
  # single process, let's tie the registry information to the lifetime of the
  # module compilation.  This is done by spinning up an ets table that stores
  # information as to the state of the registry path, its schema, and its
  # pointer.  Thus multiple entrypoints using the same schema can share
  # validation functions.

  alias Exonerate.Tools
  alias Exonerate.Type

  @spec get_table() :: :ok
  def get_table do
    if tid = Process.get(__MODULE__) do
      tid
    else
      tid = :ets.new(__MODULE__, [:set, :private])
      Process.put(__MODULE__, tid)
      tid
    end
  end

  @type state :: :needs | :built

  @spec id(state, Type.json, JsonPointer.t) :: term
  defp id(state, schema, pointer) do
    {state, :erlang.phash2(schema), pointer}
  end

  @spec register(Type.json, JsonPointer.t, atom) :: :ok | {:exists, atom} | {:needed, atom}
  def register(schema, pointer, function) do
    tid = get_table()
    built_id = id(:built, schema, pointer)
    needs_id = id(:needs, schema, pointer)
    case :ets.lookup(tid, needs_id) do
      [] ->
        case :ets.lookup(tid, built_id) do
          [] ->
            :ets.insert(tid, {built_id, function})
            :ok
          [{^built_id, function}] ->
            {:exists, function}
        end
      [{^needs_id, authority}] ->
        :ets.delete(tid, needs_id)
        :ets.insert(tid, {built_id, function})
        {:needed, Tools.jsonpointer_to_fun_name(pointer, authority: authority)}
    end
  end

  @spec request(Type.json, JsonPointer.t) :: atom
  def request(schema, pointer) do
    tid = get_table()
    id = id(:built, schema, pointer)
    case :ets.lookup(tid, id) do
      [] ->
        authority = "__registry:#{elem(id, 1)}"
        :ets.insert(tid, {id(:needs, schema, pointer), authority})
        Tools.jsonpointer_to_fun_name(pointer, authority: authority)
      [{^id, function}] ->
        function
    end
  end

  @spec needed(Type.json) :: [%{pointer: JsonPointer.t, fun: atom}]
  def needed(schema) do
    schema_hash = :erlang.phash2(schema)
    matchspec = [{{{:"$1", :"$2", :"$3"}, :"$4"}, [{:==, :needs, :"$1"}, {:==, schema_hash, :"$2"}], [%{pointer: :"$3", authority: :"$4"}]}]
    :ets.select(get_table(), matchspec)
  end

  # cache for formatting
  def format_needed(format) do
    tid = get_table()
    case :ets.lookup(tid, {:format, format}) do
      [] ->
        :ets.insert(tid, {{:format, format}})
        true
      [_] ->
        false
    end
  end

  # cache for files
  @spec get_file(Path.t) :: {:loaded, String.t} | {:cached, String.t} | {:error, term}
  def get_file(path) do
    tid = get_table()
    with [] <- :ets.lookup(tid, {:file, path}),
         {:ok, file}  <- File.read(path) do

      :ets.insert(tid, {{:file, path}, file})
      {:loaded, file}
    else
      [{{:file, ^path}, contents}] ->
        {:cached, contents}
      e = {:error, _} -> e
    end
  end

  @spec get_file!(Path.t) :: String.t
  def get_file!(path) do
    case get_file(path) do
      {:error, e} -> raise "#{e}"
      {_, contents} -> contents
    end
  end

  # if you are doing something single-threaded (like compiling multiple modules in a test), you might need to do this.
  def sweep do
    if table = Process.get(__MODULE__) do
      :ets.delete(table)
      Process.delete(__MODULE__)
    end
  end
end
