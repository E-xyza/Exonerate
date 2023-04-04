defmodule Exonerate.Formats.Iri do
  @moduledoc """
  Module which provides a macro that generates special code for an iri
  filter.  This is an absolute uri with internationalization support.

  If you require a relative uri, use `Exonerate.Formats.IriReference`.

  the format is governed by appendix A of RFC 3986, as modified by
  section 2.2 of RFC 3987:

  https://www.rfc-editor.org/rfc/rfc3986.txt
  https://www.rfc-editor.org/rfc/rfc3987.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~iri/1`.

  This function returns `{:ok, ...}` if the passed string is a valid iri,
  or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~iri"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~iri")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        IRI                  <- IRI_scheme ":" IRI_ihier_part ("?" IRI_iquery)? ("#" IRI_ifragment)?

        IRI_ihier_part       <- "//" IRI_iauthority IRI_ipath_abempty
                                / IRI_ipath_absolute
                                / IRI_ipath_rootless
                                / IRI_ipath_empty

        IRI_scheme           <- IRI_ALPHA ( IRI_ALPHA / IRI_DIGIT / "+" / "-" / "." )*

        IRI_iauthority       <- (IRI_iuserinfo "@")? IRI_ihost (":" IRI_port)?
        IRI_iuserinfo        <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / ":" )*
        IRI_ihost            <- IRI_IP_literal / IRI_IPv4address / IRI_ireg_name
        IRI_port             <- IRI_DIGIT*

        IRI_IP_literal       <- "[" ( IRI_IPv6address / IRI_IPvFuture  ) "]"

        IRI_IPvFuture        <- "v" (IRI_HEXDIG)+ "." ( IRI_unreserved / IRI_sub_delims / ":" )+

        IRI_DIGIT            <- [0-9]
        IRI_HEXDIG           <- [0-9A-Fa-f]
        IRI_ALPHA            <- [A-Za-z]

        IRI_Snum             <-  IRI_DIGIT IRI_DIGIT IRI_DIGIT

        IRI_IPv4address      <- IRI_Snum "." IRI_Snum "." IRI_Snum "." IRI_Snum

        IRI_IPv6address      <- IRI_IPv6_full / IRI_IPv6_comp / IRI_IPv6v4_full / IRI_IPv6v4_comp

        IRI_IPv6_hex         <- IRI_HEXDIG IRI_HEXDIG? IRI_HEXDIG? IRI_HEXDIG?

        IRI_IPv6_full        <- IRI_IPv6_hex ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex  ":" IRI_IPv6_hex

        IRI_IPv6_comp        <- (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)? "::"
                                (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)?

        IRI_IPv6v4_full      <- IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv6_hex ":" IRI_IPv4address

        IRI_IPv6v4_comp      <- (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)?)? "::"
                                (IRI_IPv6_hex (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? (":" IRI_IPv6_hex)? ":")?
                                IRI_IPv4address

        IRI_ireg_name        <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims )*

        IRI_ipath            <- IRI_ipath_abempty      # begins with "/" or is empty
                                / IRI_ipath_absolute   # begins with "/" but not "//"
                                / IRI_ipath_no_scheme  # begins with a non-colon IRI_segment
                                / IRI_ipath_rootless   # begins with a IRI_segment
                                / IRI_ipath_empty      # zero characters

        IRI_ipath_abempty    <- ( "/" IRI_isegment )*
        IRI_ipath_absolute   <- "/" ( IRI_isegment_nz ( "/" IRI_isegment )*)?
        IRI_ipath_no_scheme  <- IRI_isegment_nz_nc ( "/" IRI_isegment )*
        IRI_ipath_rootless   <- IRI_isegment_nz ( "/" IRI_isegment )*
        IRI_ipath_empty      <- ""

        IRI_isegment         <- IRI_ipchar*
        IRI_isegment_nz      <- IRI_ipchar+
        IRI_isegment_nz_nc   <- ( IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / "@" )+
                                # non-zero-length IRI_segment without any colon ":"

        IRI_ipchar           <- IRI_iunreserved / IRI_pct_encoded / IRI_sub_delims / ":" / "@"

        IRI_iquery           <- ( IRI_ipchar / IRI_iprivate / "/" / "?" )*

        IRI_ifragment        <- ( IRI_ipchar / "/" / "?" )*

        IRI_pct_encoded      <- "%" IRI_HEXDIG IRI_HEXDIG

        IRI_unreserved       <- IRI_ALPHA / IRI_DIGIT / "-" / "." / "_" / "~" # needed for ipVfuture
        IRI_iunreserved      <- IRI_ALPHA / IRI_DIGIT / "-" / "." / "_" / "~" / IRI_ucschar
        IRI_reserved         <- IRI_gen_delims / IRI_sub_delims
        IRI_gen_delims       <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        IRI_sub_delims       <- "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        """)

        defcombinatorp(
          :IRI_ucschar,
          utf8_char(
            not: 0..127,
            not: 0xE000..0xF8FF,
            not: 0xF0000..0xFFFFD,
            not: 0x100000..0x10FFFD
          )
        )

        defcombinatorp(
          :IRI_iprivate,
          utf8_char([0xE000..0xF8FF, 0xF0000..0xFFFFD, 0x100000..0x10FFFD])
        )

        defparsec(unquote(name), parsec(:IRI) |> eos)
      end
    end
  end
end
