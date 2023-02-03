defmodule Exonerate.Filter.UnevaluatedHelper do
  @moduledoc false

  alias Exonerate.Type

  @spec token(Type.json()) :: atom
  def token(schema) do
    case schema do
      %{"unevaluatedProperties" => _} ->
        :"evaluatedProperties-#{:erlang.phash2(schema)}"

      _ ->
        nil
    end
  end

  defmacro register_keys(tokens, key) do
    Enum.map(tokens, fn token ->
      quote bind_quoted: [evaluated_tokens: token, key: key] do
        evaluated_set =
          Process.get(evaluated_tokens) || raise "expected token #{evaluated_tokens} not found"

        Process.put(evaluated_tokens, MapSet.put(evaluated_set, key))
      end
    end)
  end
end
