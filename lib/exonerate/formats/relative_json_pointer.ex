defmodule Exonerate.Formats.RelativeJsonPointer do
  @moduledoc false

  # provides special code for a relative json pointer filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~relative-json-pointer"
  # which returns `:ok` or `{:error, reason}` if it is a valid
  # relative json pointer.

  # the format is governed by this proposal:
  # https://datatracker.ietf.org/doc/html/draft-handrews-relative-json-pointer-01

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~relative-json-pointer") do
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

        defparsec(:"~relative-json-pointer", parsec(:RJP_relative_json_pointer) |> eos)
      end
    end
  end
end
