defmodule Exonerate.Formats.Hostname do
  @moduledoc false

  # provides special code for an hostname filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~hostname"
  # which returns `:ok` or `{:error, reason}` if it is a valid
  # hostname.

  # the format is governed by section 2.1 of RFC 1123, which
  # modifies RFC 952:
  # https://www.rfc-editor.org/rfc/rfc1123.txt
  # https://www.rfc-editor.org/rfc/rfc952.txt

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~hostname") do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        HN_LetDig       <- [a-zA-Z0-9]
        HN_LetDigHypEnd <- (HN_LetDig HN_LetDigHypEnd) / ("-" HN_LetDigHypEnd) / HN_LetDig

        HN_name         <- HN_LetDig HN_LetDigHypEnd?
        HN_hname        <- HN_name ("." HN_name)*
        """)

        defparsec(:"~hostname:entrypoint", parsec(:HN_hname) |> eos)

        defp unquote(:"~hostname")(string) when byte_size(string) > 253 do
          {:error, "exceeds hostname length limit"}
        end

        defp unquote(:"~hostname")(string) do
          case unquote(:"~hostname:entrypoint")(string) do
            tuple when elem(tuple, 0) === :ok ->
              string
              |> String.split(".")
              |> Enum.reduce_while({:ok, []}, fn
                "", {:ok, []} ->
                  {:halt, {:error, "empty hostname label"}}

                part, {:ok, []} when byte_size(part) > 63 ->
                  {:halt, {:error, "exceeds hostname label length limit"}}

                part, {:ok, []} ->
                  {:cont, {:ok, []}}
              end)

            tuple when elem(tuple, 0) === :error ->
              tuple
          end
        end
      end
    end
  end
end
