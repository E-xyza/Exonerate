defmodule Exonerate.Formats.Email do
  @moduledoc """
  Module which provides a macro that generates special code for a duration
  filter.

  the format is governed by section 4.1.2 of RFC 5321:
  https://www.rfc-editor.org/rfc/rfc5321.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~email/1`.

  This function returns `{:ok, ...}` if the passed string is a valid email, or
  `{:error, reason, ...}` if it is not.  See `NimbleParsec` for more
  information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~email"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~email")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        EM_DIGIT <- [0-9]
        EM_HEXDIG <- [0-9A-Fa-f]
        EM_ALPHA <- [A-Za-z]

        EM_Snum <-  EM_DIGIT EM_DIGIT EM_DIGIT

        EM_IPv4_address_literal <- EM_Snum "." EM_Snum "." EM_Snum "." EM_Snum

        EM_IPv6_address_literal <- "IPv6:" EM_IPv6_addr

        EM_IPv6_addr <- EM_IPv6_full / EM_IPv6_comp / EM_IPv6v4_full / EM_IPv6v4_comp

        EM_IPv6_hex <- EM_HEXDIG EM_HEXDIG EM_HEXDIG EM_HEXDIG

        EM_IPv6_full <- EM_IPv6_hex ":" EM_IPv6_hex  ":" EM_IPv6_hex  ":" EM_IPv6_hex  ":" EM_IPv6_hex  ":" EM_IPv6_hex  ":" EM_IPv6_hex  ":" EM_IPv6_hex

        EM_IPv6_comp <- (EM_IPv6_hex (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)?)? "::"
                  (EM_IPv6_hex (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)?)?

        EM_IPv6v4_full <- EM_IPv6_hex ":" EM_IPv6_hex ":" EM_IPv6_hex ":" EM_IPv6_hex ":" EM_IPv6_hex ":" EM_IPv6_hex ":" EM_IPv4_address_literal

        EM_IPv6v4_comp <- (EM_IPv6_hex (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)?)? "::"
                  (EM_IPv6_hex (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? (":" EM_IPv6_hex)? ":")?
                  EM_IPv4_address_literal

        EM_Let_dig <- EM_ALPHA / EM_DIGIT

        EM_Ldh_str <- EM_Let_dig EM_Ldh_str / "-" EM_Ldh_str / EM_Let_dig

        EM_Standardized_tag <- EM_Ldh_str

        EM_dcontent <- [!-Z^-~]

        EM_General_address_literal <- EM_Standardized_tag ":" EM_dcontent?

        EM_sub_domain <- EM_Let_dig EM_Ldh_str?

        EM_Domain <- EM_sub_domain ("." EM_sub_domain)*

        EM_address_literal  <- "[" ( EM_IPv4_address_literal /
                                      EM_IPv6_address_literal /
                                      EM_General_address_literal ) "]"

        EM_atext <-   EM_ALPHA / EM_DIGIT / "!" / "#" /  "$" / "%" /  "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"

        EM_Atom           <- EM_atext+

        EM_Dot_string <- EM_Atom ("." EM_Atom)*

        EM_quoted_pairSMTP  <- "\\" / " " / [!-~]

        EM_qtextSMTP      <- " " / "!" / [#-Z] / "[" / "]" /  [^-~]

        EM_QcontentSMTP   <- EM_qtextSMTP / EM_quoted_pairSMTP

        EM_Quoted_string  <- "\"" EM_QcontentSMTP* "\""

        EM_Local_part <- EM_Dot_string

        EM_Mailbox  <-  EM_Local_part "@" ( EM_Domain / EM_address_literal )
        """)

        defparsec(unquote(name), parsec(:EM_Mailbox) |> eos)
      end
    end
  end
end
