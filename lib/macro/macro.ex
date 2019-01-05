defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  defmacro defschema([{method, json} | _opts]) do
    code = json
    |> Jason.decode!
    |> matcher(method)

    quote do
      unquote_splicing(code)
    end
  end

  @spec matcher(any, any)::[{:def, any, any}]
  def matcher(map, method) when map == %{}, do: [always_matches(method)]
  def matcher(true, method), do: [always_matches(method)]
  def matcher(false, method), do: [never_matches(method)]

  @spec always_matches(atom) :: {:def, any, any}
  def always_matches(method) do
    quote do
      def unquote(method)(_val) do
        :ok
      end
    end
  end

  @spec never_matches(atom) :: {:def, any, any}
  def never_matches(method) do
    quote do
      def unquote(method)(val) do
        {:mismatch, {__MODULE__, Atom.to_string(unquote(method))}, val}
      end
    end
  end
end
