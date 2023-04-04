defmodule Exonerate.Formats.RelativeJsonPointer do
  @moduledoc """
  Module which provides a macro that generates special code for a relative json
  pointer filter.

  the format is governed by this proposal:
  https://datatracker.ietf.org/doc/html/draft-handrews-relative-json-pointer-01
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~relative-json-pointer/1`.

  This function returns `{:ok, ...}` if the passed string is a valid relative
  json pointer, or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~relative-json-pointer"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~relative-json-pointer")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string("""
        RJP_relative_json_pointer <- RJP_non_negative_integer ("#" / RJP_json_pointer)
        RJP_non_negative_integer  <- "0" / ([1-9] [0-9]*)
                # "0", or digits without a leading "0"

        RJP_json_pointer    <- ( "/" RJP_reference_token )*
        RJP_reference_token <- ( RJP_unescaped / RJP_escaped )*
        RJP_escaped         <- "~" ( "0" / "1" )
          # representing '~' and '/', respectively
        """)

        defcombinatorp(:RJP_unescaped, utf8_char(not: 0x2F, not: 0x7E))
        # 0x2F ('/') and 0x7E ('~') are excluded from 'unescaped'

        defparsec(unquote(name), parsec(:RJP_relative_json_pointer) |> eos)
      end
    end
  end
end
