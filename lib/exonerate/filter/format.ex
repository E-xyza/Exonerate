defmodule Exonerate.Filter.Format do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Exonerate.Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Exonerate.Tools.maybe_dump(opts)
  end

  def should_format?(_resource, _pointer, format, opts) do
    opts = Keyword.get(opts, :format)

    cond do
      format === "binary" -> false
      !opts -> false
      opts === true -> true
      # TODO: delete this.
      true -> false
    end
  end

  # privileged formats
  defp build_filter("date-time", resource, pointer, opts) do
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

  defp build_filter("date", resource, pointer, opts) do
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

  defp build_filter("time", resource, pointer, opts) do
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

  defp build_filter("ipv4", resource, pointer, opts) do
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

  defp build_filter("ipv6", resource, pointer, opts) do
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

  defp build_filter("uuid", resource, pointer, opts) do
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
    "relative-json-pointer" => Exonerate.Formats.RelativeJsonPointer
  }

  for {filter, module} <- @format_filters do
    defp build_filter(unquote(filter), resource, pointer, opts) do
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
end
