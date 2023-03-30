defmodule Exonerate.Formats.Hostname do
  @moduledoc false

  # provides special code for an hostname filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~hostname?"
  # which returns a boolean depending on whether the string is a valid
  # hostname.

  # the format is governed by section 2.1 of RFC 1123, which
  # modifies RFC 952:
  # https://www.rfc-editor.org/rfc/rfc1123.txt
  # https://www.rfc-editor.org/rfc/rfc952.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~hostname?") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        HN_LetDig <- [a-zA-Z0-9]
        HN_LetDigHypEnd <- (HN_LetDig HN_LetDigHypEnd) / ("-" HN_LetDigHypEnd) / HN_LetDig

        HN_name  <- HN_LetDig HN_LetDigHypEnd?
        HN_hname <- HN_name ("." HN_name)*

        """)

        defparsec(:"~hostname?", parsec(:HN_hname) |> eos)
      end
    end
  end
end
