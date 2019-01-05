defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  defmacro defschema([{method, json} | _opts]) do
    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    quote do
      unquote(code)
    end
  end

  @spec matcher(any, any)::{:def, any, any} | {:__block__, any, any}
  def matcher(map, method) when map == %{}, do: always_matches(method)
  def matcher(true, method), do: always_matches(method)
  def matcher(false, method), do: never_matches(method)
  def matcher(spec = %{"$schema" => schema}, method), do: match_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method), do: match_id(spec, id, method)
  def matcher(spec = %{"type" => "string"}, method), do: match_string(spec, method)

  @spec always_matches(atom) :: {:def, any, any}
  defp always_matches(method) do
    quote do
      def unquote(method)(_val) do
        :ok
      end
    end
  end

  @spec never_matches(atom) :: {:def, any, any}
  defp never_matches(method) do
    quote do
      def unquote(method)(val) do
        {:mismatch, {__MODULE__, Atom.to_string(unquote(method))}, val}
      end
    end
  end

  @spec match_schema(map, String.t, atom) :: {:__block__, any, any}
  def match_schema(map, schema, module) do
    rest = map
    |> Map.delete("$schema")
    |> matcher(module)

    quote do
      def schema, do: unquote(schema)
      unquote(rest)
    end
  end

  @spec match_id(map, String.t, atom) :: {:__block__, any, any}
  def match_id(map, id, module) do
    rest = map
    |> Map.delete("$id")
    |> matcher(module)

    quote do
      def id, do: unquote(id)
      unquote(rest)
    end
  end

  @spec match_string(map, atom) :: {:__block__, any, [{:def, any, any}]}
  defp match_string(_spec, method) do
    quote do
      def unquote(method)(val) when is_binary(val) do
        :ok
      end
      def unquote(method)(val) do
        {:mismatch, {__MODULE__, Atom.to_string(unquote(method))}, val}
      end
    end
  end

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(b) when is_binary(b), do: b
end
