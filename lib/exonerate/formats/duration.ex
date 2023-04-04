defmodule Exonerate.Formats.Duration do
  @moduledoc """
  Module which provides a macro that generates special code for a duration
  filter.

  This format is governed by appendix A of RFC 3339:
  https://www.rfc-editor.org/rfc/rfc3339.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~duration/1`.

  This function returns `{:ok, ...}` if the passed string is a valid duration,
  or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for more
  information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~duration"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~duration")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string("""
        DUR_DIGIT <- [0-9]
        DUR_DIGITS <- DUR_DIGIT+

        second <- DUR_DIGITS "S"
        minute <- DUR_DIGITS "M" second?
        hour   <- DUR_DIGITS "H" minute?
        time   <- "T" (hour / minute / second)
        day    <- DUR_DIGITS "D"
        week   <- DUR_DIGITS "W"
        month  <- DUR_DIGITS "M" day?
        year   <- DUR_DIGITS "Y" month?
        date   <- (day / month / year) time?

        duration   <- "P" (date / time / week)
        """)

        defparsec(unquote(name), parsec(:duration) |> eos)
      end
    end
  end
end
