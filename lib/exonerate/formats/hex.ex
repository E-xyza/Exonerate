defmodule Exonerate.Formats.Hex do
  @moduledoc false

  # provides special code for a hexadecimal character guard

  # the format is governed by appendix A of RFC 3339:
  # https://www.rfc-editor.org/rfc/rfc3339.txt

  alias Exonerate.Cache

  defmacro guard do
    if Cache.register_context(__CALLER__.module, :is_hex) do
      quote do
        defguard is_hex(char) when char in ?0..?9 or char in ?a..?f or char in ?A..?F
      end
    end
  end
end
