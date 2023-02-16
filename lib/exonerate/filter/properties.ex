defmodule Exonerate.Filter.Properties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  # TODO: figure out requireds
  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    tracker = Keyword.fetch!(opts, :tracker)

    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(pointer)
    |> Enum.map(&filter_for(&1, call, name, pointer, tracker, opts))
    |> Enum.unzip()
    |> build_code(call, tracker)
    |> Tools.maybe_dump(opts)
  end

  defp filter_for({key, _schema}, call, name, pointer, tracker, opts) do
    key_pointer = JsonPointer.traverse(pointer, key)
    key_call = Tools.pointer_to_fun_name(key_pointer, authority: name)

    filter =
      case tracker do
        :tracked ->
          quote do
            defp unquote(call)({unquote(key), value}, path, _seen) do
              case unquote(key_call)(value, Path.join(path, unquote(key))) do
                :ok -> {:ok, true}
                error -> error
              end
            end
          end

        :untracked ->
          quote do
            defp unquote(call)({unquote(key), value}, path) do
              unquote(key_call)(value, Path.join(path, unquote(key)))
            end
          end
      end

    {filter,
     quote do
       require Exonerate.Context
       Exonerate.Context.from_cached(unquote(name), unquote(key_pointer), unquote(opts))
     end}
  end

  defp build_code({filters, accessories}, call, :tracked) do
    quote do
      unquote(filters)

      defp unquote(call)(_kv, _path, seen), do: {:ok, seen}

      unquote(accessories)
    end
  end

  defp build_code({filters, accessories}, call, :untracked) do
    quote do
      unquote(filters)

      defp unquote(call)(_kv, _path), do: :ok

      unquote(accessories)
    end
  end
end
