defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    # a ref might be:

    # - reference to something local (usually starts with #)
    # - reference to something set with an id
    # - remote reference.

    # condition the options to accept unevaluatedProperties
    opts =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
      |> case do
        %{"unevaluatedProperties" => _} -> Keyword.put(opts, :track_properties, true)
        _ -> opts
      end

    module = __CALLER__.module

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> URI.parse()
    |> build_code(module, name, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp normalize(fragment = "/" <> _), do: fragment
  defp normalize(fragment), do: "/" <> fragment

  defp build_code(
         %{host: nil, path: nil, fragment: fragment},
         module,
         name,
         call_pointer,
         opts
       ) do
    ref_pointer =
      fragment
      |> normalize
      |> JsonPointer.from_uri()

    tracked = opts[:track_items] || opts[:track_properties]

    call =
      call_pointer
      |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    call_path = JsonPointer.to_uri(call_pointer)

    opts = Keyword.delete(opts, :id)

    ref = Tools.pointer_to_fun_name(ref_pointer, authority: name)

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(ref_pointer)
    |> Tools.degeneracy()
    |> case do
      :ok ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(_content, _path)  do
            require Exonerate.Combining
            Exonerate.Combining.initialize(unquote(tracked))
          end
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
          Exonerate.Context.from_cached(unquote(name), unquote(ref_pointer), unquote(opts))
        end

      :unknown ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(content, path) do
            case unquote(ref)(content, path) do
              {:error, error} ->
                ref_trace = Keyword.get(error, :ref_trace, [])
                new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
                {:error, new_error}

              ok -> ok
            end
          end

          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(ref_pointer), unquote(opts))
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
