defmodule Exonerate.Formats.Email do
  @moduledoc false

  # provides special code for an email filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~email?"
  # which returns a boolean depending on whether the string is a valid
  # email.

  # the format is governed by section 4.1.2 of RFC 5321:
  # https://www.rfc-editor.org/rfc/rfc5321.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~email?") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        DIGIT <- [0-9]
        HEXDIG <- [0-9A-Fa-f]
        ALPHA <- [A-Za-z]

        Snum <-  DIGIT DIGIT DIGIT

        IPv4_address_literal <- Snum "." Snum "." Snum "." Snum

        IPv6_address_literal <- "IPv6:" IPv6_addr

        IPv6_addr <- IPv6_full / IPv6_comp / IPv6v4_full / IPv6v4_comp

        IPv6_hex <- HEXDIG HEXDIG HEXDIG HEXDIG

        IPv6_full <- IPv6_hex ":" IPv6_hex  ":" IPv6_hex  ":" IPv6_hex  ":" IPv6_hex  ":" IPv6_hex  ":" IPv6_hex  ":" IPv6_hex

        IPv6_comp <- (IPv6_hex (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)?)? "::"
                  (IPv6_hex (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)?)?

        IPv6v4_full <- IPv6_hex ":" IPv6_hex ":" IPv6_hex ":" IPv6_hex ":" IPv6_hex ":" IPv6_hex ":" IPv4_address_literal

        IPv6v4_comp <- (IPv6_hex (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)?)? "::"
                  (IPv6_hex (":" IPv6_hex)? (":" IPv6_hex)? (":" IPv6_hex)? ":")?
                  IPv4_address_literal

        Let_dig <- ALPHA / DIGIT

        Ldh_str <- ("\-" Ldh_str) / Let_dig

        Standardized_tag <- Ldh_str

        dcontent <- [!-Z^-~]

        General_address_literal <- Standardized_tag ":" dcontent?

        sub_domain <- Let_dig Ldh_str?

        Domain <- sub_domain ("." sub_domain)*

        address_literal  <- "[" ( IPv4_address_literal /
                                      IPv6_address_literal /
                                      General_address_literal ) "]"


        atext <-   ALPHA / DIGIT / "!" / "#" /  "$" / "%" /  "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"

        Atom           <- atext+

        Dot_string <- Atom ("." Atom)*

        quoted_pairSMTP  <- "foo" # "\92" [\32-\126]

        qtextSMTP      <- "bar" # [\32-\33] / [\35-\91] / [\93-\126]

        QcontentSMTP   <- qtextSMTP / quoted_pairSMTP

        Quoted_string  <- "\"" QcontentSMTP* "\""

        Local_part <- Dot_string

        Mailbox  <-  Local_part "@" ( Domain / address_literal )
        """)

        defparsec(:"~email?", parsec(:Mailbox) |> eos)
      end
    end
  end
end
