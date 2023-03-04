defmodule Exonerate.Filter.Properties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    {tracked, opts} = Keyword.pop!(opts, :internal_tracking)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.map(&filter_for(&1, call, name, pointer, tracked, opts))
    |> Enum.unzip()
    |> build_filter(call, tracked)
    |> Tools.maybe_dump(opts)
  end

  @should_track [:additional, :unevaluated]

  defp filter_for({key, _schema}, call, name, pointer, tracked, opts) do
    key_pointer = JsonPointer.join(pointer, key)
    key_call = Tools.pointer_to_fun_name(key_pointer, authority: name)

    filter =
      if tracked in @should_track do
        quote do
          defp unquote(call)({unquote(key), value}, path, _seen) do
            case unquote(key_call)(value, Path.join(path, unquote(key))) do
              :ok -> {:ok, true}
              error -> error
            end
          end
        end
      else
        quote do
          defp unquote(call)({unquote(key), value}, path) do
            unquote(key_call)(value, Path.join(path, unquote(key)))
          end
        end
      end

    {filter,
     quote do
       require Exonerate.Context
       Exonerate.Context.filter(unquote(name), unquote(key_pointer), unquote(opts))
     end}
  end

  defp build_filter({filters, accessories}, call, tracked) do
    if tracked in @should_track do
      quote do
        unquote(filters)

        defp unquote(call)(_kv, _path, seen), do: {:ok, seen}

        unquote(accessories)
      end
    else
      quote do
        unquote(filters)

        defp unquote(call)(_kv, _path), do: :ok

        unquote(accessories)
      end
    end
  end
end
