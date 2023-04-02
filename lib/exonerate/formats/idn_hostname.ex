defmodule Exonerate.Formats.IdnHostname do
  @moduledoc false

  # provides special code for an idn hostname filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~idn-hostname?"
  # which returns a boolean depending on whether the string is a valid
  # hostname.

  # the format is governed by section 2.1 of RFC 1123, which
  # modifies RFC 952:
  # https://www.rfc-editor.org/rfc/rfc1123.txt
  # https://www.rfc-editor.org/rfc/rfc952.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~idn-hostname") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IDN_HN_LetDig <- [a-zA-Z0-9] / IDN_HN_UTF8_non_ascii
        IDN_HN_LetDigHypEnd <- (IDN_HN_LetDig IDN_HN_LetDigHypEnd) / ("-" IDN_HN_LetDigHypEnd) / IDN_HN_LetDig

        IDN_HN_name  <- IDN_HN_LetDig IDN_HN_LetDigHypEnd?
        IDN_HN_hname <- IDN_HN_name ("." IDN_HN_name)*

        """)

        defparsec(:IDN_HN_UTF8_non_ascii, utf8_char(not: 0..127))
        defparsec(:"~idn-hostname:entrypoint", parsec(:IDN_HN_hname) |> eos)

        defp unquote(:"~idn-hostname")(string) when byte_size(string) > 253 do
          {:error, "exceeds hostname length limit"}
        end

        defp unquote(:"~idn-hostname")(string) do
          segments = String.split(string, ".")

          with {:ok, unicode} <- unquote(:"~idn-hostname:punycode-normalize")(segments) do
            unquote(:"~idn-hostname:entrypoint")(IO.iodata_to_binary(unicode))
          end
        end

        defp unquote(:"~idn-hostname:punycode-normalize")(segments) do
          case Enum.reduce_while(
                 segments,
                 {:ok, [], 0},
                 &unquote(:"~idn-hostname:punycode-segment")(&1, &2, nil)
               ) do
            {:ok, _, length} when length >= 253 -> {:error, "exceeds hostname length limit"}
            {:ok, unicode_rev, length} -> Enum.reverse(unicode_rev)
            error -> error
          end
        end

        @__punycode_prefixes ~w(xn-- XN-- Xn-- xN--)

        defp unquote(:"~idn-hostname:punycode-segment")(
               <<prefix::binary-size(4), segment::binary>>,
               {:ok, so_far, 0},
               nil
             )
             when prefix in @__punycode_prefixes do
        end
      end
    end
  end
end
