defmodule Exonerate.Filter.Format do
  @moduledoc false

  alias Exonerate.Tools

  @format_filters %{
    "duration" => Exonerate.Formats.Duration,
    "email" => Exonerate.Formats.Email,
    "idn-email" => Exonerate.Formats.IdnEmail,
    "hostname" => Exonerate.Formats.Hostname,
    "idn-hostname" => Exonerate.Formats.IdnHostname,
    "uri" => Exonerate.Formats.Uri,
    "uri-reference" => Exonerate.Formats.UriReference,
    "iri" => Exonerate.Formats.Iri,
    "iri-reference" => Exonerate.Formats.IriReference,
    "uri-template" => Exonerate.Formats.UriTemplate,
    "json-pointer" => Exonerate.Formats.JsonPointer,
    "relative-json-pointer" => Exonerate.Formats.RelativeJsonPointer,
    "regex" => Exonerate.Formats.Regex
  }

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Exonerate.Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Exonerate.Tools.maybe_dump(opts)
  end

  @default_filters Map.keys(@format_filters) ++
                     ~w(date-time date-time-utc date-time-tz date time ipv4 ipv6 uuid)

  def should_format?(format, resource, pointer, opts) do
    format_opts = format_opts(opts)

    cond do
      format === "binary" -> false
      format in @default_filters and format_opts[:default] -> true
      find_type_override(format, format_opts) -> true
      find_at_override(resource, pointer, format_opts) -> true
      true -> false
    end
  end

  defp build_filter(format, resource, pointer, opts) do
    format_opts = format_opts(opts)
    # check to see if the opts is a kwl and if it's a kwl, extract the
    cond do
      custom = find_at_override(resource, pointer, format_opts) ->
        build_custom(custom, resource, pointer, opts)

      custom = find_type_override(format, format_opts) ->
        build_custom(custom, resource, pointer, opts)

      format in @default_filters and format_opts[:default] ->
        build_default(format, resource, pointer, opts)
    end
  end

  # privileged formats
  defp build_default("date-time", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        string
        |> String.upcase()
        |> NaiveDateTime.from_iso8601()
        |> case do
          {:ok, _} -> :ok
          {:error, _} -> Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("date-time-utc", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        string
        |> String.upcase()
        |> DateTime.from_iso8601()
        |> case do
          {:ok, _, 0} ->
            :ok

          {:ok, _, offset} ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path,
              reason: "timezone must be 0, got #{offset / 3600} hours"
            )

          {:error, _} ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("date-time-tz", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        string
        |> String.upcase()
        |> DateTime.from_iso8601()
        |> case do
          {:ok, %{utc_offset: _}, _} -> :ok
          {:error, _} -> Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("date", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        case Date.from_iso8601(string) do
          {:ok, _} -> :ok
          {:error, _} -> Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("time", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        case Time.from_iso8601(string) do
          {:ok, _} -> :ok
          {:error, _} -> Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("ipv4", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        # NB ipv4strict means no "shortened ipv4 addresses"
        case :inet.parse_ipv4strict_address(to_charlist(string)) do
          {:ok, _} -> :ok
          {:error, _} -> Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("ipv6", resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        # NB :inet.parse_ipv6strict_address accepts ipv6 zone id's.  We need to reject these.
        with [_] <- String.split(string, "%"),
             # NB ipv6strict means "no ipv4 addresses"
             {:ok, _} <- :inet.parse_ipv6strict_address(to_charlist(string)) do
          :ok
        else
          [_ | _] ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path,
              reason: "ipv6 addresses can't contain zone ids"
            )

          _ ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path)
        end
      end
    end
  end

  defp build_default("uuid", resource, pointer, opts) do
    quote do
      require Exonerate.Formats.Hex
      Exonerate.Formats.Hex.guard()

      defp unquote(Tools.call(resource, pointer, opts))(
             <<
               a0,
               a1,
               a2,
               a3,
               a4,
               a5,
               a6,
               a7,
               ?-,
               b0,
               b1,
               b2,
               b3,
               ?-,
               c0,
               c1,
               c2,
               c3,
               ?-,
               d0,
               d1,
               d2,
               d3,
               ?-,
               e0,
               e1,
               e2,
               e3,
               e4,
               e5,
               e6,
               e7,
               e8,
               e9,
               e10,
               e11
             >>,
             _path
           )
           when is_hex(a0) and is_hex(a1) and is_hex(a2) and is_hex(a3) and is_hex(a4) and
                  is_hex(a5) and is_hex(a6) and is_hex(a7) and
                  is_hex(b0) and is_hex(b1) and is_hex(b2) and is_hex(b3) and
                  is_hex(c0) and is_hex(c1) and is_hex(c2) and is_hex(c3) and
                  is_hex(d0) and is_hex(d1) and is_hex(d2) and is_hex(d3) and
                  is_hex(e0) and is_hex(e1) and is_hex(e2) and is_hex(e3) and is_hex(e4) and
                  is_hex(e5) and is_hex(e6) and is_hex(e7) and
                  is_hex(e8) and is_hex(e9) and is_hex(e10) and is_hex(e11) do
        :ok
      end

      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(string, unquote(pointer), path)
      end
    end
  end

  for {filter, module} <- @format_filters do
    defp build_default(unquote(filter), resource, pointer, opts) do
      call = :"~#{unquote(filter)}"
      mod = unquote(module)

      quote do
        require unquote(mod)
        unquote(mod).filter()

        defp unquote(Tools.call(resource, pointer, opts))(string, path) do
          require Exonerate.Tools

          case unquote(call)(string) do
            tuple when elem(tuple, 0) == :ok ->
              :ok

            tuple when elem(tuple, 0) == :error ->
              Exonerate.Tools.mismatch(string, unquote(pointer), path, reason: elem(tuple, 1))
          end
        end
      end
    end
  end

  defp build_default(filter, resource, pointer, opts) do
    opts = Keyword.get(opts, :format)

    if is_list(opts) do
      types = List.wrap(if is_list(opts), do: opts[:types])
      pointers = List.wrap(if is_list(opts), do: opts[:at])

      uri =
        pointer
        |> JsonPointer.to_uri()
        |> to_string
        |> Tools.if(
          String.starts_with?(resource, "function://"),
          &String.replace_leading(&1, resource, "")
        )

      cond do
        {_, spec} = List.keyfind(types, filter, 0) ->
          build_custom(spec, resource, pointer, opts)

        {_, spec} = List.keyfind(pointers, uri, 0) ->
          build_custom(spec, resource, pointer, opts)

        true ->
          []
      end
    else
      []
    end
  end

  defp build_custom({:{}, _, [m, f, a]}, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        case apply(unquote(m), unquote(f), [string | unquote(a)]) do
          :ok ->
            :ok

          {:error, reason} ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path, reason: reason)
        end
      end
    end
  end

  defp build_custom({m, f}, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        case apply(unquote(m), unquote(f), [string]) do
          :ok ->
            :ok

          {:error, reason} ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path, reason: reason)
        end
      end
    end
  end

  defp build_custom(m, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(string, path) do
        require Exonerate.Tools

        case apply(unquote(m), :validate, [string]) do
          :ok ->
            :ok

          {:error, reason} ->
            Exonerate.Tools.mismatch(string, unquote(pointer), path, reason: reason)
        end
      end
    end
  end

  defp format_opts(opts) do
    case Keyword.get(opts, :format) do
      nil -> []
      :default -> [default: true]
      opts when is_list(opts) -> opts
    end
  end

  defp find_type_override(format, format_opts) do
    kv =
      format_opts
      |> Keyword.get(:types, [])
      |> List.keyfind(format, 0)

    if kv, do: elem(kv, 1)
  end

  defp find_at_override(resource, pointer, format_opts) do
    prefix =
      if String.starts_with?(resource, "function://") do
        ""
      else
        resource
      end

    selector =
      pointer
      |> JsonPointer.backtrack!()
      |> JsonPointer.to_uri()
      |> to_string
      |> String.replace_prefix("", prefix)

    kv =
      format_opts
      |> Keyword.get(:at, [])
      |> List.keyfind(selector, 0)

    if kv, do: elem(kv, 1)
  end
end
