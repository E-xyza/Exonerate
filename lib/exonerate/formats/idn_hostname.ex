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
    if Cache.register_context(__CALLER__.module, :"~idn-hostname?") do
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
        defparsec(:"~idn-hostname?", parsec(:IDN_HN_hname) |> eos)
      end
    end
  end
end
