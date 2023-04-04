defmodule Exonerate.Formats.IdnHostname do
  @moduledoc """
  Module which provides a macro that generates special code for an idn-hostname
  filter.  This is a hostname with internationalization support.

  the format is governed by section 2.1 of RFC 1123, which
  modifies RFC 952:
  https://www.rfc-editor.org/rfc/rfc1123.txt
  https://www.rfc-editor.org/rfc/rfc952.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a parser `~idn-hostname/1`.

  This function returns `{:ok}` if the passed string is a valid idn hostname, or
  `{:error, reason}` if it is not.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  > ### Warning {: .warning}
  >
  > this function generates code that requires the `:idna` library.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~idn-hostname"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~idn-hostname")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IDN_HN_LetDig       <- [a-zA-Z0-9] / IDN_HN_UTF8_non_ascii
        IDN_HN_LetDigHypEnd <- (IDN_HN_LetDig IDN_HN_LetDigHypEnd) / ("-" IDN_HN_LetDig IDN_HN_LetDigHypEnd) / IDN_HN_LetDig

        IDN_HN_name         <- IDN_HN_LetDig IDN_HN_LetDigHypEnd?
        IDN_HN_hname        <- IDN_HN_name ("." IDN_HN_name)*
        """)

        defcombinatorp(:IDN_HN_UTF8_non_ascii, utf8_char(not: 0..127))
        defparsec(:"~idn-hostname:entrypoint", parsec(:IDN_HN_hname) |> eos)

        defp unquote(name)(string) when byte_size(string) > 253 do
          {:error, "exceeds hostname length limit"}
        end

        defp unquote(name)(string) do
          segments = String.split(string, ".")

          with {:ok, unicode} <- unquote(:"~idn-hostname:punycode-normalize")(segments),
               tuple when elem(tuple, 0) === :ok <-
                 unquote(:"~idn-hostname:entrypoint")(IO.iodata_to_binary(unicode)) do
            {:ok}
          else
            tuple when elem(tuple, 0) === :error ->
              {:error, elem(tuple, 1)}
          end
        end

        defp unquote(:"~idn-hostname:punycode-normalize")(segments) do
          case Enum.reduce_while(
                 segments,
                 {:ok, [], 0},
                 fn a, b -> unquote(:"~idn-hostname:punycode-segment")(a, b) end
               ) do
            {:ok, unicode_rev, _length} -> {:ok, Enum.reverse(unicode_rev)}
            error -> error
          end
        end

        @__punycode_prefixes ~w(xn-- XN-- Xn-- xN--)
        defp unquote(:"~idn-hostname:punycode-segment")(
               full_string = <<prefix::binary-size(4), segment::binary>>,
               {:ok, so_far, size_so_far}
             )
             when prefix in @__punycode_prefixes do
          string_size = byte_size(full_string)

          case string_size do
            this_size when this_size > 63 ->
              {:halt, {:error, "exceeds hostname label length limit"}}

            this_size when this_size + size_so_far > 253 ->
              {:halt, {:error, "exceeds hostname length limit"}}

            this_size ->
              try do
                unicode = :punycode.decode(String.to_charlist(segment))

                {:cont, {:ok, [List.to_string(unicode) | so_far], size_so_far + this_size}}
              catch
                _, what ->
                  {:halt, {:error, "invalid punycode content: #{segment}"}}
              end
          end
        end

        defp unquote(:"~idn-hostname:punycode-segment")(full_string, {:ok, so_far, size_so_far}) do
          # check to see if there are any non-ascii characters in our string.
          string_size =
            if unquote(:"~idn-hostname:all-ascii?")(full_string) do
              byte_size(full_string)
            else
              # this is inefficient, we could do this in a single pass also without actually
              # performing a full decode.
              full_string
              |> String.to_charlist()
              |> :punycode.encode()
              |> Enum.count()
            end

          case string_size do
            this_size when this_size > 63 ->
              {:halt, {:error, "exceeds hostname label length limit"}}

            this_size when this_size + size_so_far > 253 ->
              {:halt, {:error, "exceeds hostname length limit"}}

            this_size ->
              {:cont, {:ok, [full_string | so_far], this_size + size_so_far}}
          end
        end

        defp unquote(:"~idn-hostname:all-ascii?")(string) do
          case string do
            <<>> -> true
            <<x, rest::binary>> when x < 128 -> unquote(:"~idn-hostname:all-ascii?")(rest)
            _ -> false
          end
        end
      end
    end
  end
end
