defmodule Exonerate.Formats.Uri do
  @moduledoc """
  Module which provides a macro that generates special code for a uri.
  This is an absolute uri.

  If you require a relative uri, use `Exonerate.Formats.UriReference`.

  the format is governed by appendix A of RFC 3986:
  https://www.rfc-editor.org/rfc/rfc3986.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~uri/1`.

  This function returns `{:ok, ...}` if the passed string is a valid uri,
  or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~uri"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~uri")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        URI               <- URI_scheme ":" URI_hier_part ("?" URI_query)? ("#" URI_fragment)?

        URI_hier_part     <- "//" URI_authority URI_path_abempty
                            / URI_path_absolute
                            / URI_path_rootless
                            / URI_path_empty

        URI_scheme        <- URI_ALPHA ( URI_ALPHA / URI_DIGIT / "+" / "-" / "." )*

        URI_authority     <- (URI_userinfo "@")? URI_host (":" URI_port)?
        URI_userinfo      <- ( URI_unreserved / URI_pct_encoded / URI_sub_delims / ":" )*
        URI_host          <- URI_IP_literal / URI_IPv4address / URI_reg_name
        URI_port          <- URI_DIGIT*

        URI_IP_literal    <- "[" ( URI_IPv6address / URI_IPvFuture  ) "]"

        URI_IPvFuture     <- "v" (URI_HEXDIG)+ "." ( URI_unreserved / URI_sub_delims / ":" )+

        URI_DIGIT         <- [0-9]
        URI_HEXDIG        <- [0-9A-Fa-f]
        URI_ALPHA         <- [A-Za-z]

        URI_Snum          <-  URI_DIGIT URI_DIGIT URI_DIGIT

        URI_IPv4address   <- URI_Snum "." URI_Snum "." URI_Snum "." URI_Snum

        URI_IPv6address   <- URI_IPv6_full / URI_IPv6_comp / URI_IPv6v4_full / URI_IPv6v4_comp

        URI_IPv6_hex      <- URI_HEXDIG URI_HEXDIG? URI_HEXDIG? URI_HEXDIG?

        URI_IPv6_full     <- URI_IPv6_hex ":" URI_IPv6_hex  ":" URI_IPv6_hex  ":" URI_IPv6_hex  ":" URI_IPv6_hex  ":" URI_IPv6_hex  ":" URI_IPv6_hex  ":" URI_IPv6_hex

        URI_IPv6_comp     <- (URI_IPv6_hex (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)?)? "::"
                             (URI_IPv6_hex (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)?)?

        URI_IPv6v4_full   <- URI_IPv6_hex ":" URI_IPv6_hex ":" URI_IPv6_hex ":" URI_IPv6_hex ":" URI_IPv6_hex ":" URI_IPv6_hex ":" URI_IPv4address

        URI_IPv6v4_comp   <- (URI_IPv6_hex (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)?)? "::"
                             (URI_IPv6_hex (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? (":" URI_IPv6_hex)? ":")?
                             URI_IPv4address

        URI_reg_name      <- ( URI_unreserved / URI_pct_encoded / URI_sub_delims )*

        URI_path          <- URI_path_abempty          # begins with "/" or is empty
                             / URI_path_absolute       # begins with "/" but not "//"
                             / URI_path_no_scheme      # begins with a non-colon URI_segment
                             / URI_path_rootless       # begins with a URI_segment
                             / URI_path_empty          # zero characters

        URI_path_abempty    <- ( "/" URI_segment )*
        URI_path_absolute   <- "/" ( URI_segment_nz ( "/" URI_segment )*)?
        URI_path_no_scheme  <- URI_segment_nz_nc ( "/" URI_segment )*
        URI_path_rootless   <- URI_segment_nz ( "/" URI_segment )*
        URI_path_empty      <- ""

        URI_segment         <- URI_pchar*
        URI_segment_nz      <- URI_pchar+
        URI_segment_nz_nc   <- ( URI_unreserved / URI_pct_encoded / URI_sub_delims / "@" )+
                               # non-zero-length URI_segment without any colon ":"

        URI_pchar           <- URI_unreserved / URI_pct_encoded / URI_sub_delims / ":" / "@"

        URI_query           <- ( URI_pchar / "/" / "?" )*

        URI_fragment        <- ( URI_pchar / "/" / "?" )*

        URI_pct_encoded     <- "%" URI_HEXDIG URI_HEXDIG

        URI_unreserved      <- URI_ALPHA / URI_DIGIT / "-" / "." / "_" / "~"
        URI_reserved        <- URI_gen_delims / URI_sub_delims
        URI_gen_delims      <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        URI_sub_delims      <- "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        """)

        defparsec(unquote(name), parsec(:URI) |> eos)
      end
    end
  end
end
