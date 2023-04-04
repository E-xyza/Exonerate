defmodule Exonerate.Formats.UriReference do
  @moduledoc """
  Module which provides a macro that generates special code for a uri filter.

  the format is governed by appendix A of RFC 3986:
  https://www.rfc-editor.org/rfc/rfc3986.txt
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~uri-reference/1`.

  This function returns `{:ok, ...}` if the passed string is a valid uri
  reference, or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for
  more information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~uri-reference"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~uri-reference")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        URI_REFERENCE           <- URI_REF_URI / URI_REF_relative_ref

        URI_REF_relative_ref    <- URI_REF_relative_part ("?" URI_REF_query)? ("#" URI_REF_fragment)?

        URI_REF_relative_part   <- "//" URI_REF_authority URI_REF_path_abempty
                                  / URI_REF_path_absolute
                                  / URI_REF_path_no_scheme
                                  / URI_REF_path_empty

        URI_REF_URI             <- URI_REF_scheme ":" URI_REF_hier_part ("?" URI_REF_query)? ("#" URI_REF_fragment)?

        URI_REF_hier_part       <- "//" URI_REF_authority URI_REF_path_abempty
                                  / URI_REF_path_absolute
                                  / URI_REF_path_rootless
                                  / URI_REF_path_empty

        URI_REF_scheme          <- URI_REF_ALPHA ( URI_REF_ALPHA / URI_REF_DIGIT / "+" / "-" / "." )*

        URI_REF_authority       <- (URI_REF_userinfo "@")? URI_REF_host (":" URI_REF_port)?
        URI_REF_userinfo        <- ( URI_REF_unreserved / URI_REF_pct_encoded / URI_REF_sub_delims / ":" )*
        URI_REF_host            <- URI_REF_IP_literal / URI_REF_IPv4address / URI_REF_reg_name
        URI_REF_port            <- URI_REF_DIGIT*

        URI_REF_IP_literal      <- "[" ( URI_REF_IPv6address / URI_REF_IPvFuture  ) "]"

        URI_REF_IPvFuture       <- "v" (URI_REF_HEXDIG)+ "." ( URI_REF_unreserved / URI_REF_sub_delims / ":" )+

        URI_REF_DIGIT           <- [0-9]
        URI_REF_HEXDIG          <- [0-9A-Fa-f]
        URI_REF_ALPHA           <- [A-Za-z]

        URI_REF_Snum            <- URI_REF_DIGIT URI_REF_DIGIT URI_REF_DIGIT

        URI_REF_IPv4address     <- URI_REF_Snum "." URI_REF_Snum "." URI_REF_Snum "." URI_REF_Snum

        URI_REF_IPv6address     <- URI_REF_IPv6_full / URI_REF_IPv6_comp / URI_REF_IPv6v4_full / URI_REF_IPv6v4_comp

        URI_REF_IPv6_hex        <- URI_REF_HEXDIG URI_REF_HEXDIG? URI_REF_HEXDIG? URI_REF_HEXDIG?

        URI_REF_IPv6_full       <- URI_REF_IPv6_hex ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex  ":" URI_REF_IPv6_hex

        URI_REF_IPv6_comp       <- (URI_REF_IPv6_hex (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)?)? "::"
                                   (URI_REF_IPv6_hex (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)?)?

        URI_REF_IPv6v4_full     <- URI_REF_IPv6_hex ":" URI_REF_IPv6_hex ":" URI_REF_IPv6_hex ":" URI_REF_IPv6_hex ":" URI_REF_IPv6_hex ":" URI_REF_IPv6_hex ":" URI_REF_IPv4address

        URI_REF_IPv6v4_comp     <- (URI_REF_IPv6_hex (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)?)? "::"
                                   (URI_REF_IPv6_hex (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? (":" URI_REF_IPv6_hex)? ":")?
                                   URI_REF_IPv4address

        URI_REF_reg_name        <- ( URI_REF_unreserved / URI_REF_pct_encoded / URI_REF_sub_delims )*

        URI_REF_path            <- URI_REF_path_abempty      # begins with "/" or is empty
                                   / URI_REF_path_absolute   # begins with "/" but not "//"
                                   / URI_REF_path_no_scheme  # begins with a non-colon URI_REF_segment
                                   / URI_REF_path_rootless   # begins with a URI_REF_segment
                                   / URI_REF_path_empty      # zero characters

        URI_REF_path_abempty    <- ( "/" URI_REF_segment )*
        URI_REF_path_absolute   <- "/" ( URI_REF_segment_nz ( "/" URI_REF_segment )*)?
        URI_REF_path_no_scheme  <- URI_REF_segment_nz_nc ( "/" URI_REF_segment )*
        URI_REF_path_rootless   <- URI_REF_segment_nz ( "/" URI_REF_segment )*
        URI_REF_path_empty      <- ""

        URI_REF_segment         <- URI_REF_pchar*
        URI_REF_segment_nz      <- URI_REF_pchar+
        URI_REF_segment_nz_nc   <- ( URI_REF_unreserved / URI_REF_pct_encoded / URI_REF_sub_delims / "@" )+
                                  # non-zero-length URI_REF_segment without any colon ":"

        URI_REF_pchar           <- URI_REF_unreserved / URI_REF_pct_encoded / URI_REF_sub_delims / ":" / "@"

        URI_REF_query           <- ( URI_REF_pchar / "/" / "?" )*

        URI_REF_fragment        <- ( URI_REF_pchar / "/" / "?" )*

        URI_REF_pct_encoded     <- "%" URI_REF_HEXDIG URI_REF_HEXDIG

        URI_REF_unreserved      <- URI_REF_ALPHA / URI_REF_DIGIT / "-" / "." / "_" / "~"
        URI_REF_reserved        <- URI_REF_gen_delims / URI_REF_sub_delims
        URI_REF_gen_delims      <- ":" / "/" / "?" / "#" / "[" / "]" / "@"
        URI_REF_sub_delims      <- "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        """)

        defparsec(unquote(name), parsec(:URI_REFERENCE) |> eos)
      end
    end
  end
end
