defmodule Exonerate.Formats.UriTemplate do
  @moduledoc """
  Module which provides a macro that generates special code for a uri template.

  the format is governed by RFC 6570:
  https://www.rfc-editor.org/rfc/rfc6570.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~uri-template/1`.

  This function returns `{:ok, ...}` if the passed string is a valid uri
  template, or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~uri-template"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~uri-template")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        URI_TEMPLATE            <- URI_TMP_URI / URI_TMP_irelative_ref

        URI_TMP_irelative_ref    <- URI_TMP_irelative_part (("?" URI_TMP_iquery) / URI_TMP_query_expr)? (("#" URI_TMP_ifragment) / URI_TMP_frag_expr)?

        URI_TMP_irelative_part   <- "//" URI_TMP_iauthority URI_TMP_ipath_abempty
                                    / URI_TMP_ipath_absolute
                                    / URI_TMP_ipath_no_scheme
                                    / URI_TMP_ipath_empty

        URI_TMP_URI              <- URI_TMP_scheme ":" URI_TMP_ihier_part ("?" URI_TMP_iquery)? ("#" URI_TMP_ifragment)?

        URI_TMP_ihier_part       <- "//" URI_TMP_iauthority URI_TMP_ipath_abempty
                                    #/ URI_TMP_ipath_absolute
                                    #/ URI_TMP_ipath_rootless
                                    #/ URI_TMP_ipath_empty

        URI_TMP_scheme           <- URI_TMP_ALPHA ( URI_TMP_ALPHA / URI_TMP_DIGIT / "+" / "-" / "." )*

        URI_TMP_iauthority       <- (URI_TMP_iuserinfo "@")? URI_TMP_ihost (":" URI_TMP_port)?
        URI_TMP_iuserinfo        <- ( URI_TMP_iunreserved / URI_TMP_pct_encoded / URI_TMP_sub_delims / ":" )*
        URI_TMP_ihost            <- URI_TMP_IP_literal / URI_TMP_IPv4address / URI_TMP_ireg_name
        URI_TMP_port             <- URI_TMP_DIGIT*

        URI_TMP_IP_literal       <- "[" ( URI_TMP_IPv6address / URI_TMP_IPvFuture  ) "]"

        URI_TMP_IPvFuture        <- "v" (URI_TMP_HEXDIG)+ "." ( URI_TMP_unreserved / URI_TMP_sub_delims / ":" )+

        URI_TMP_DIGIT            <- [0-9]
        URI_TMP_HEXDIG           <- [0-9A-Fa-f]
        URI_TMP_ALPHA            <- [A-Za-z]

        URI_TMP_Snum             <-  URI_TMP_DIGIT URI_TMP_DIGIT URI_TMP_DIGIT

        URI_TMP_IPv4address      <- URI_TMP_Snum "." URI_TMP_Snum "." URI_TMP_Snum "." URI_TMP_Snum

        URI_TMP_IPv6address      <- URI_TMP_IPv6_full / URI_TMP_IPv6_comp / URI_TMP_IPv6v4_full / URI_TMP_IPv6v4_comp

        URI_TMP_IPv6_hex         <- URI_TMP_HEXDIG URI_TMP_HEXDIG URI_TMP_HEXDIG URI_TMP_HEXDIG

        URI_TMP_IPv6_full        <- URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex  ":" URI_TMP_IPv6_hex

        URI_TMP_IPv6_comp        <- (URI_TMP_IPv6_hex (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)?)? "::"
                                    (URI_TMP_IPv6_hex (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)?)?

        URI_TMP_IPv6v4_full      <- URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex ":" URI_TMP_IPv6_hex ":" URI_TMP_IPv4address

        URI_TMP_IPv6v4_comp      <- (URI_TMP_IPv6_hex (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)?)? "::"
                                    (URI_TMP_IPv6_hex (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? (":" URI_TMP_IPv6_hex)? ":")?
                                    URI_TMP_IPv4address

        URI_TMP_ireg_name        <- ( URI_TMP_iunreserved / URI_TMP_pct_encoded / URI_TMP_sub_delims )*

        URI_TMP_ipath            <- URI_TMP_ipath_abempty       # begins with "/" or is empty
                                    / URI_TMP_ipath_absolute    # begins with "/" but not "//"
                                    / URI_TMP_ipath_no_scheme   # begins with a non-colon URI_TMP_segment
                                    / URI_TMP_ipath_rootless    # begins with a URI_TMP_segment
                                    / URI_TMP_ipath_empty       # zero characters

        URI_TMP_dot_expr         <- "{" "."? URI_TMP_variable_list "}"
        URI_TMP_path_expr        <- "{" ("/" ";")? URI_TMP_variable_list "}"
        URI_TMP_query_expr       <- "{" "?" URI_TMP_variable_list "}"
        URI_TMP_param_expr       <- "{" "&" URI_TMP_variable_list "}"
        URI_TMP_frag_expr        <- "{" "#" URI_TMP_variable_list "}"

        URI_TMP_variable_list    <- URI_TMP_varspec ("," URI_TMP_varspec)*
        URI_TMP_varspec          <- URI_TMP_varname URI_TMP_mod_l4?
        URI_TMP_varname          <- URI_TMP_varchar ("."? URI_TMP_varchar)*
        URI_TMP_varchar          <- URI_TMP_ALPHA / URI_TMP_DIGIT / "_" / URI_TMP_pct_encoded

        URI_TMP_mod_l4           <- URI_TMP_prefix / URI_TMP_explode
        URI_TMP_prefix           <- ":" URI_TMP_max_length
        URI_TMP_max_length       <- [1-9] URI_TMP_DIGIT? URI_TMP_DIGIT? URI_TMP_DIGIT?   # positive integer < 10000
        URI_TMP_explode          <- "*"

        URI_TMP_ipath_abempty    <- ( "/" URI_TMP_isegment )*
        URI_TMP_ipath_absolute   <- "/" ( URI_TMP_isegment_nz ( "/" URI_TMP_isegment )*)?
        URI_TMP_ipath_no_scheme  <- URI_TMP_isegment_nz_nc ( "/" URI_TMP_isegment )*
        URI_TMP_ipath_rootless   <- URI_TMP_isegment_nz ( "/" URI_TMP_isegment )*
        URI_TMP_ipath_empty      <- ""

        URI_TMP_isegment         <- URI_TMP_path_expr / URI_TMP_ipchar*
        URI_TMP_isegment_nz      <- URI_TMP_path_expr / URI_TMP_ipchar+
        URI_TMP_isegment_nz_nc   <- ( URI_TMP_iunreserved / URI_TMP_pct_encoded / URI_TMP_sub_delims / "@" )+
                                    # non-zero-length URI_TMP_segment without any colon ":"

        URI_TMP_ipchar           <- URI_TMP_iunreserved / URI_TMP_pct_encoded / URI_TMP_sub_delims / ":" / "@"

        URI_TMP_iquery           <- ( URI_TMP_param_expr / URI_TMP_ipchar / URI_TMP_iprivate / "/" / "?" )*

        URI_TMP_ifragment        <- ( URI_TMP_ipchar / "/" / "?" )*

        URI_TMP_pct_encoded      <- "%" URI_TMP_HEXDIG URI_TMP_HEXDIG

        URI_TMP_unreserved       <- URI_TMP_ALPHA / URI_TMP_DIGIT / "-" / "." / "_" / "~" # needed for ipVfuture
        URI_TMP_iunreserved      <- URI_TMP_dot_expr / URI_TMP_ALPHA / URI_TMP_DIGIT / "-" / "." / "_" / "~" / URI_TMP_ucschar
        URI_TMP_reserved         <- URI_TMP_gen_delims / URI_TMP_sub_delims
        URI_TMP_gen_delims       <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        URI_TMP_sub_delims       <- "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        """)

        defcombinatorp(
          :URI_TMP_ucschar,
          utf8_char(
            not: 0..127,
            not: 0xE000..0xF8FF,
            not: 0xF0000..0xFFFFD,
            not: 0x100000..0x10FFFD
          )
        )

        defcombinatorp(
          :URI_TMP_iprivate,
          utf8_char([0xE000..0xF8FF, 0xF0000..0xFFFFD, 0x100000..0x10FFFD])
        )

        defparsec(unquote(name), parsec(:URI_TEMPLATE) |> eos)
      end
    end
  end
end
