defmodule Exonerate.Formats.JsonPointer do
  @moduledoc """
  Module which provides a macro that generates special code for a json
  pointer filter.

  the format is governed by Section 3 of RFC 6901:
  https://www.rfc-editor.org/rfc/rfc6901.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~json-pointer/1`.

  This function returns `{:ok, ...}` if the passed string is a valid json
  pointer, or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~json-pointer"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~json-pointer")

    if Cache.register_context(__CALLER__.module, name) do
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

        defparsec(unquote(name), parsec(:JP_json_pointer) |> eos)
      end
    end
  end
end
