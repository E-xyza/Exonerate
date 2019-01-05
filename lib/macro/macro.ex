defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  defmacro defschema([{method, json} | _opts]) do
    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    code2 = quote do
      unquote_splicing(code)
    end

    IO.puts("")
    code2
    |> Macro.to_string
    |> Code.format_string!
    |> Enum.join
    |> IO.puts

    code2
  end

  @spec matcher(any, any)::[{:def, any, any} | {:__block__, any, any}]
  def matcher(map, method) when map == %{}, do: [always_matches(method)]
  def matcher(true, method), do: [always_matches(method)]
  def matcher(false, method), do: never_matches(method)
  def matcher(spec = %{"$schema" => schema}, method), do: match_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method), do: match_id(spec, id, method)
  def matcher(spec = %{"type" => "string"}, method), do: match_string(spec, method)
  def matcher(spec = %{"type" => "number"}, method), do: match_number(spec, method)
  def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)

  @spec always_matches(atom) :: {:def, any, any}
  defp always_matches(method) do
    quote do
      def unquote(method)(_val) do
        :ok
      end
    end
  end

  @spec never_matches(atom) :: [{:def, any, any}]
  defp never_matches(method) do
    [quote do
      def unquote(method)(val) do
        {:mismatch, {__MODULE__, unquote(method)}, val}
      end
    end]
  end

  @spec match_schema(map, String.t, atom) :: [{:def, any, any}]
  def match_schema(map, schema, module) do
    rest = map
    |> Map.delete("$schema")
    |> matcher(module)


    [quote do
       def schema, do: unquote(schema)
     end | rest]
  end

  @spec match_id(map, String.t, atom) :: [{:def, any, any}]
  def match_id(map, id, module) do
    rest = map
    |> Map.delete("$id")
    |> matcher(module)


    [quote do
      def id, do: unquote(id)
     end | rest]
  end

  @spec match_string(map, atom, boolean) :: [{:def, any, any}]
  defp match_string(_spec, method, terminal \\ true) do
    str_match = quote do
      def unquote(method)(val) when is_binary(val) do
        :ok
      end
    end

    if terminal do
      [str_match | never_matches(method)]
    else
      [str_match]
    end
  end

  @spec match_number(map, atom, boolean) :: [{:def, any, any}]
  defp match_number(_spec, method, terminal \\ true) do
    num_match = quote do
      def unquote(method)(val) when is_number(val) do
        :ok
      end
    end

    if terminal do
      [num_match | never_matches(method)]
    else
      [num_match]
    end
  end

  @spec match_list(map, list, atom) :: [{:def, any, any}]
  defp match_list(_spec, [], method), do: never_matches(method)
  defp match_list(spec, ["string" | tail], method) do
    head_code = match_string(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["number" | tail], method) do
    head_code = match_number(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(b) when is_binary(b), do: b
end
