defmodule Exonerate.Formats.IdnEmail do
  @moduledoc false

  # provides special code for an idn-email filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~email?"
  # which returns a boolean depending on whether the string is a valid
  # email.

  # the format is governed by section 3.3 of RFC 6531:
  # https://www.rfc-editor.org/rfc/rfc6531.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~idn-email") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IDN_EM_DIGIT <- [0-9]
        IDN_EM_HEXDIG <- [0-9A-Fa-f]
        IDN_EM_ALPHA <- [A-Za-z]

        IDN_EM_Snum <-  IDN_EM_DIGIT IDN_EM_DIGIT IDN_EM_DIGIT

        IDN_EM_IPv4_address_literal <- IDN_EM_Snum "." IDN_EM_Snum "." IDN_EM_Snum "." IDN_EM_Snum

        IDN_EM_IPv6_address_literal <- "IPv6:" IDN_EM_IPv6_addr

        IDN_EM_IPv6_addr <- IDN_EM_IPv6_full / IDN_EM_IPv6_comp / IDN_EM_IPv6v4_full / IDN_EM_IPv6v4_comp

        IDN_EM_IPv6_hex <- IDN_EM_HEXDIG IDN_EM_HEXDIG IDN_EM_HEXDIG IDN_EM_HEXDIG

        IDN_EM_IPv6_full <- IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex  ":" IDN_EM_IPv6_hex

        IDN_EM_IPv6_comp <- (IDN_EM_IPv6_hex (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)?)? "::"
                  (IDN_EM_IPv6_hex (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)?)?

        IDN_EM_IPv6v4_full <- IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex ":" IDN_EM_IPv6_hex ":" IDN_EM_IPv4_address_literal

        IDN_EM_IPv6v4_comp <- (IDN_EM_IPv6_hex (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)?)? "::"
                  (IDN_EM_IPv6_hex (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? (":" IDN_EM_IPv6_hex)? ":")?
                  IDN_EM_IPv4_address_literal

        IDN_EM_Let_dig <- IDN_EM_ALPHA / IDN_EM_DIGIT

        IDN_EM_Ldh_str <- ("\-" IDN_EM_Ldh_str) / IDN_EM_Let_dig

        IDN_EM_Standardized_tag <- IDN_EM_Ldh_str

        IDN_EM_dcontent <- [!-Z^-~]

        IDN_EM_General_address_literal <- IDN_EM_Standardized_tag ":" IDN_EM_dcontent?

        IDN_EM_sub_domain <- (IDN_EM_Let_dig IDN_EM_Ldh_str?) / IDN_EM_U_label

        IDN_EM_Domain <- IDN_EM_sub_domain ("." IDN_EM_sub_domain)*

        IDN_EM_address_literal  <- "[" ( IDN_EM_IPv4_address_literal /
                                      IDN_EM_IPv6_address_literal /
                                      IDN_EM_General_address_literal ) "]"

        IDN_EM_atext <-   IDN_EM_ALPHA / IDN_EM_DIGIT / "!" / "#" /  "$" / "%" /  "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~" / IDN_EM_UTF8_non_ascii

        IDN_EM_allowedascii <-   IDN_EM_ALPHA / IDN_EM_DIGIT / "!" / "#" /  "$" / "%" /  "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"

        IDN_EM_U_label <- IDN_EM_UTF8_non_ascii / IDN_EM_allowedascii IDN_EM_U_label / IDN_EM_UTF8_non_ascii IDN_EM_U_label

        IDN_EM_Atom           <- IDN_EM_atext+

        IDN_EM_Dot_string <- IDN_EM_Atom ("." IDN_EM_Atom)*

        IDN_EM_quoted_pairSMTP  <- "\134" [\40-\176]

        IDN_EM_qtextSMTP      <- [\40-\41] / [\43-\133] / [\135-\176] / IDN_EM_UTF8_non_ascii

        IDN_EM_QcontentSMTP   <- IDN_EM_qtextSMTP / IDN_EM_quoted_pairSMTP

        IDN_EM_Quoted_string  <- "\"" IDN_EM_QcontentSMTP* "\""

        IDN_EM_Local_part <- IDN_EM_Dot_string

        IDN_EM_Mailbox  <-  IDN_EM_Local_part "@" ( IDN_EM_Domain / IDN_EM_address_literal )
        """)

        defparsec(:IDN_EM_UTF8_non_ascii, utf8_char(not: 0..127))
        defparsec(:"~idn-email", parsec(:IDN_EM_Mailbox))
      end
    end
  end
end
