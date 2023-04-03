defmodule Exonerate.Formats.JsonPointer do
  @moduledoc false

  # provides special code for a json pointer filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~json-pointer"
  # which returns `:ok` or `{:error, reason}` if it is a valid
  # json pointer.

  # the format is governed by Section 3 of RFC 6901:
  # https://www.rfc-editor.org/rfc/rfc6901.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~json-pointer") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string("""
        JP_json_pointer    <- ( "/" JP_reference_token )*
        JP_reference_token <- ( JP_unescaped / JP_escaped )*
        JP_escaped         <- "~" ( "0" / "1" )
          # representing '~' and '/', respectively
        """)

        defcombinatorp(:JP_unescaped, utf8_char(not: 0x2F, not: 0x7E))
        # 0x2F ('/') and 0x7E ('~') are excluded from 'unescaped'

        defparsec(:"~json-pointer", parsec(:JP_json_pointer) |> eos)
      end
    end
  end
end
