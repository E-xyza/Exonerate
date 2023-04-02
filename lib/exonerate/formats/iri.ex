defmodule Exonerate.Formats.Iri do
  @moduledoc false

  # provides special code for an iri filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "iri?"
  # which returns a boolean depending on whether the string is a valid
  # iri.

  # the format is governed by appendix A of RFC 3986, as modified by
  # section 2.2 of RFC 3987

  # https://www.rfc-editor.org/rfc/rfc3986.txt
  # https://www.rfc-editor.org/rfc/rfc3987.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~iri") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IRI           <- IRI_scheme ":" IRI_ihier_part ("?" IRI_iquery)? ("#" IRI_ifragment)?

        IRI_ihier_part     <- "//" IRI_iauthority IRI_ipath_abempty
                         / IRI_ipath_absolute
                         / IRI_ipath_rootless
                         / IRI_ipath_empty

        IRI_scheme        <- IRI_ALPHA ( IRI_ALPHA / IRI_DIGIT / "+" / "-" / "." )*

        IRI_iauthority     <- (IRI_iuserinfo "@")? IRI_ihost (":" IRI_port)?
        IRI_iuserinfo      <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / ":" )*
        IRI_ihost          <- IRI_IP_literal / IRI_IPv4address / IRI_ireg_name
        IRI_port          <- IRI_DIGIT*

        IRI_IP_literal    <- "[" ( IRI_IPv6address / IRI_IPvFuture  ) "]"

        IRI_IPvFuture     <- "v" (IRI_HEXDIG)+ "." ( IRI_unreserved / IRI_sub_delims / ":" )+

        IRI_DIGIT <- [0-9]
        IRI_HEXDIG <- [0-9A-Fa-f]
        IRI_ALPHA <- [A-Za-z]

        IRI_Snum <-  IRI_DIGIT IRI_DIGIT IRI_DIGIT

        IRI_IPv4address <- IRI_Snum "." IRI_Snum "." IRI_Snum "." IRI_Snum

        IRI_IPv6address <- IRI_IPv6_full / IRI_IPv6_comp / IRI_IPv6v4_full / IRI_IPv6v4_comp

        IRI_IPv6_hex <- IRI_HEXDIG IRI_HEXDIG? IRI_HEXDIG? IRI_HEXDIG?

        IRI_IPv6_full <- IRI_IPv6_hex ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex

        IRI_IPv6_comp <- (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)? "::"
                  (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)?

        IRI_IPv6v4_full <- IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv4address

        IRI_IPv6v4_comp <- (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)? "::"
                  (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? ":")?
                  IRI_IPv4address

        IRI_ireg_name      <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims )*

        IRI_ipath          <- IRI_ipath_abempty    # begins with "/" or is empty
                       / IRI_ipath_absolute   # begins with "/" but not "//"
                       / IRI_ipath_no_scheme   # begins with a non-colon IRI_segment
                       / IRI_ipath_rootless   # begins with a IRI_segment
                       / IRI_ipath_empty      # zero characters

        IRI_ipath_abempty  <- ( "/" IRI_isegment )*
        IRI_ipath_absolute <- "/" ( IRI_isegment_nz ( "/" IRI_isegment )*)?
        IRI_ipath_no_scheme <- IRI_isegment_nz_nc ( "/" IRI_isegment )*
        IRI_ipath_rootless <- IRI_isegment_nz ( "/" IRI_isegment )*
        IRI_ipath_empty    <- ""

        IRI_isegment       <- IRI_ipchar*
        IRI_isegment_nz    <- IRI_ipchar+
        IRI_isegment_nz_nc <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / "@" )+
                 # non-zero-length IRI_segment without any colon ":"

        IRI_ipchar         <- IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / ":" / "@"

        IRI_iquery         <- ( IRI_ipchar / "/" / "?" )*

        IRI_ifragment      <- ( IRI_ipchar / "/" / "?" )*

        IRI_pct_encoded   <- "%" IRI_HEXDIG IRI_HEXDIG

        IRI_unreserved    <- IRI_ALPHA / IRI_DIGIT / "-" / "." / "_" / "~" # needed for ipVfuture
        IRI_iunreserved    <- IRI_ALPHA / IRI_DIGIT / "-" / "." / "_" / "~" / IRI_ucschar
        IRI_reserved      <- IRI_gen_delims / IRI_sub_delims
        IRI_gen_delims    <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        IRI_sub_delims    <- "!" / "$" / "&" / "'" / "(" / ")"
                 / "*" / "+" / "," / ";" / "="
        """)

        defcombinatorp(:IRI_ucschar, utf8_char(not: 0..127))

        defparsec(:"~iri", parsec(:IRI) |> eos)
      end
    end
  end
end
