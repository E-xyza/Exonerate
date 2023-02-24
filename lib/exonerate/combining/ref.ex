defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    # a ref might be:

    # - reference to something local (usually starts with #)
    # - reference to something set with an id
    # - remote reference.

    call = Tools.pointer_to_fun_name(pointer, authority: name)
    call_path = JsonPointer.to_uri(pointer)

    module = __CALLER__.module

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> URI.parse()
    |> build_code(module, name, call, call_path, opts)
    |> Tools.maybe_dump(opts)
  end

  defp normalize(fragment = "/" <> _), do: fragment
  defp normalize(fragment), do: "/" <> fragment

  defp build_code(
         a = %{host: nil, path: nil, fragment: fragment},
         module,
         name,
         call,
         call_path,
         opts
       ) do
    pointer =
      fragment
      |> normalize
      |> JsonPointer.from_uri()

    opts = Keyword.delete(opts, :id)

    ref = Tools.pointer_to_fun_name(pointer, authority: name)

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Tools.determined()
    |> case do
      :ok ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(_content, _path), do: :ok
        end

      :error ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(content, path) do
            {:error, error} = unquote(ref)(content, path)
            ref_trace = Keyword.get(error, :ref_trace, [])
            new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
            {:error, new_error}
          end

          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
        end

      :unknown ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(content, path) do
            case unquote(ref)(content, path) do
              :ok ->
                :ok

              {:error, error} ->
                ref_trace = Keyword.get(error, :ref_trace, [])
                new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
                {:error, new_error}
            end
          end

          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
        end
    end
  end

  defp build_code(%{host: nil, path: path}, module, name, call, call_path, opts) do
    pointer =
      opts
      |> Keyword.fetch!(:id)
      |> URI.parse()
      |> Map.replace!(:path, "/" <> path)
      |> to_string()
      |> Cache.get_id(module)

    opts = Keyword.delete(opts, :id)

    ref = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        case unquote(ref)(content, path) do
          :ok ->
            :ok

          {:error, error} ->
            ref_trace = Keyword.get(error, :ref_trace, [])
            new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
            {:error, new_error}
        end
      end

      require Exonerate.Context
      Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
