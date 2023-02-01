defmodule Exonerate.Filter.UnevaluatedHelper do
  @moduledoc false
  defmacro register_key(nil, _key) do
    quote do
    end
  end

  defmacro register_key(token, key) do
    quote bind_quoted: [unevaluated_token: token, key: key] do
      evaluated_set =
        Process.get(unevaluated_token) || raise "expected token #{unevaluated_token} not found"

      Process.put(unevaluated_token, MapSet.put(evaluated_set, key))
    end
  end
end
