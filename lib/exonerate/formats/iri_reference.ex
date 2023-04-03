defmodule Exonerate.Formats.IriReference do
  @moduledoc false

  # provides special code for an iri reference filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~iri-reference"
  # which returns `:ok` or `{:error, reason}` if it is a valid
  # iri reference.

  # the format is governed by appendix A of RFC 3986:
  # https://www.rfc-editor.org/rfc/rfc3986.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~iri-reference") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IRI_REFERENCE            <- IRI_REF_URI / IRI_REF_irelative_ref

        IRI_REF_irelative_ref    <- IRI_REF_irelative_part ("?" IRI_REF_iquery)? ("#" IRI_REF_ifragment)?

        IRI_REF_irelative_part   <- "//" IRI_REF_iauthority IRI_REF_ipath_abempty
                                    / IRI_REF_ipath_absolute
                                    / IRI_REF_ipath_no_scheme
                                    / IRI_REF_ipath_empty

        IRI_REF_URI              <- IRI_REF_scheme ":" IRI_REF_ihier_part ("?" IRI_REF_iquery)? ("#" IRI_REF_ifragment)?

        IRI_REF_ihier_part       <- "//" IRI_REF_iauthority IRI_REF_ipath_abempty
                                    / IRI_REF_ipath_absolute
                                    / IRI_REF_ipath_rootless
                                    / IRI_REF_ipath_empty

        IRI_REF_scheme           <- IRI_REF_ALPHA ( IRI_REF_ALPHA / IRI_REF_DIGIT / "+" / "-" / "." )*

        IRI_REF_iauthority       <- (IRI_REF_iuserinfo "@")? IRI_REF_ihost (":" IRI_REF_port)?
        IRI_REF_iuserinfo        <- ( IRI_REF_iunreserved / IRI_REF_pct_encoded / IRI_REF_sub_delims / ":" )*
        IRI_REF_ihost            <- IRI_REF_IP_literal / IRI_REF_IPv4address / IRI_REF_ireg_name
        IRI_REF_port             <- IRI_REF_DIGIT*

        IRI_REF_IP_literal       <- "[" ( IRI_REF_IPv6address / IRI_REF_IPvFuture  ) "]"

        IRI_REF_IPvFuture        <- "v" (IRI_REF_HEXDIG)+ "." ( IRI_REF_unreserved / IRI_REF_sub_delims / ":" )+

        IRI_REF_DIGIT            <- [0-9]
        IRI_REF_HEXDIG           <- [0-9A-Fa-f]
        IRI_REF_ALPHA            <- [A-Za-z]

        IRI_REF_Snum             <-  IRI_REF_DIGIT IRI_REF_DIGIT IRI_REF_DIGIT

        IRI_REF_IPv4address      <- IRI_REF_Snum "." IRI_REF_Snum "." IRI_REF_Snum "." IRI_REF_Snum

        IRI_REF_IPv6address      <- IRI_REF_IPv6_full / IRI_REF_IPv6_comp / IRI_REF_IPv6v4_full / IRI_REF_IPv6v4_comp

        IRI_REF_IPv6_hex         <- IRI_REF_HEXDIG IRI_REF_HEXDIG IRI_REF_HEXDIG IRI_REF_HEXDIG

        IRI_REF_IPv6_full        <- IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex  ":" IRI_REF_IPv6_hex

        IRI_REF_IPv6_comp        <- (IRI_REF_IPv6_hex (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)?)? "::"
                                    (IRI_REF_IPv6_hex (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)?)?

        IRI_REF_IPv6v4_full      <- IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex ":" IRI_REF_IPv6_hex ":" IRI_REF_IPv4address

        IRI_REF_IPv6v4_comp      <- (IRI_REF_IPv6_hex (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)?)? "::"
                                    (IRI_REF_IPv6_hex (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? (":" IRI_REF_IPv6_hex)? ":")?
                                    IRI_REF_IPv4address

        IRI_REF_ireg_name        <- ( IRI_REF_iunreserved / IRI_REF_pct_encoded / IRI_REF_sub_delims )*

        IRI_REF_ipath            <- IRI_REF_ipath_abempty       # begins with "/" or is empty
                                    / IRI_REF_ipath_absolute    # begins with "/" but not "//"
                                    / IRI_REF_ipath_no_scheme   # begins with a non-colon IRI_REF_segment
                                    / IRI_REF_ipath_rootless    # begins with a IRI_REF_segment
                                    / IRI_REF_ipath_empty       # zero characters

        IRI_REF_ipath_abempty    <- ( "/" IRI_REF_isegment )*
        IRI_REF_ipath_absolute   <- "/" ( IRI_REF_isegment_nz ( "/" IRI_REF_isegment )*)?
        IRI_REF_ipath_no_scheme  <- IRI_REF_isegment_nz_nc ( "/" IRI_REF_isegment )*
        IRI_REF_ipath_rootless   <- IRI_REF_isegment_nz ( "/" IRI_REF_isegment )*
        IRI_REF_ipath_empty      <- ""

        IRI_REF_isegment         <- IRI_REF_ipchar*
        IRI_REF_isegment_nz      <- IRI_REF_ipchar+
        IRI_REF_isegment_nz_nc   <- ( IRI_REF_iunreserved / IRI_REF_pct_encoded / IRI_REF_sub_delims / "@" )+
                                    # non-zero-length IRI_REF_segment without any colon ":"

        IRI_REF_ipchar           <- IRI_REF_iunreserved / IRI_REF_pct_encoded / IRI_REF_sub_delims / ":" / "@"

        IRI_REF_iquery           <- ( IRI_REF_ipchar / IRI_REF_iprivate / "/" / "?" )*

        IRI_REF_ifragment        <- ( IRI_REF_ipchar / "/" / "?" )*

        IRI_REF_pct_encoded      <- "%" IRI_REF_HEXDIG IRI_REF_HEXDIG

        IRI_REF_unreserved       <- IRI_REF_ALPHA / IRI_REF_DIGIT / "-" / "." / "_" / "~" # needed for ipVfuture
        IRI_REF_iunreserved      <- IRI_REF_ALPHA / IRI_REF_DIGIT / "-" / "." / "_" / "~" / IRI_REF_ucschar
        IRI_REF_reserved         <- IRI_REF_gen_delims / IRI_REF_sub_delims
        IRI_REF_gen_delims       <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        IRI_REF_sub_delims       <- "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        """)

        defcombinatorp(:IRI_REF_ucschar, utf8_char(not: 0..127, not: 0xE000..0xF8FF, not: 0xF0000..0xFFFFD, not: 0x100000..0x10FFFD))
        defcombinatorp(:IRI_REF_iprivate, utf8_char([0xE000..0xF8FF, 0xF0000..0xFFFFD, 0x100000..0x10FFFD]))

        defparsec(:"~iri-reference", parsec(:IRI_REFERENCE) |> eos)
      end
    end
  end
end
