defmodule Exonerate.Formats.Duration do
  @moduledoc false

  # provides special code for a duration filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~duration?"
  # which returns a boolean depending on whether the string is a valid
  # duration.

  # the format is governed by appendix A of RFC 3339:
  # https://www.rfc-editor.org/rfc/rfc3339.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~duration?") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string("""
        DIGIT <- [0-9]
        DIGITS <- DIGIT+

        second <- DIGITS "S"
        minute <- DIGITS "M" second?
        hour   <- DIGITS "H" minute?
        time   <- "T" (hour / minute / second)
        day    <- DIGITS "D"
        week   <- DIGITS "W"
        month  <- DIGITS "M" day?
        year   <- DIGITS "Y" month?
        date   <- (day / month / year) time?

        duration   <- "P" (date / time / week)
        """)

        defparsec(:"~duration?", parsec(:duration) |> eos)
      end
    end
  end
end
