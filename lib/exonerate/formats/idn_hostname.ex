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
            {:ok, unicode_rev, length} -> {:ok, Enum.reverse(unicode_rev)}
            error -> error
          end
        end

        @__punycode_prefixes ~w(xn-- XN-- Xn-- xN--)
        defp unquote(:"~idn-hostname:punycode-segment")(
               full_string = <<prefix::binary-size(4), segment::binary>>,
               {:ok, so_far, size_so_far},
               nil
             )
             when prefix in @__punycode_prefixes do

          string_size = byte_size(full_string)

          case string_size do
            size when size > 63 ->
              {:halt, {:error, "exceeds hostname label length limit"}}
            size when size + size_so_far > 253 ->
              {:halt, {:error, "exceeds hostname length limit"}}

            _ ->
              try do
                unicode = :punycode.decode(String.to_charlist(segment))
                {:cont, {:ok, [List.to_string(unicode) | so_far], size_so_far + byte_size(full_string)}}
              catch
                _, what ->
                  {:halt, {:error, "invalid punycode content: #{segment}"}}
              end
          end
        end
      end
    end
  end
end
