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

  defmacro register_tokens(tokens, key) do
    Enum.map(tokens, fn token ->
      quote bind_quoted: [evaluated_tokens: token, key: key] do
        evaluated_set =
          Process.get(evaluated_tokens) || raise "expected token #{evaluated_tokens} not found"

        Process.put(evaluated_tokens, MapSet.put(evaluated_set, key))
      end
    end)
  end

  defmacro fetch_tokens(tokens) do
    quote do
      Map.new(unquote(tokens), fn token ->
        {token, Process.get(token) || raise("expected token #{token} not found")}
      end)
    end
  end

  defmacro purge_tokens(tokens) do
    quote do
      Enum.each(unquote(tokens), &Process.put(&1, MapSet.new()))
    end
  end

  defmacro restore_tokens(tokens, temp_var) do
    quote do
      Enum.each(unquote(tokens), &Process.put(&1, Map.fetch!(unquote(temp_var), &1)))
    end
  end
end
