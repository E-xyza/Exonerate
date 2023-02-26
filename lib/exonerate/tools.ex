defmodule Exonerate.Tools do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Type

  def inspect(macro, filter \\ true) do
    if filter do
      macro
      |> Macro.to_string()
      |> IO.puts()
    end

    macro
  end

  def maybe_dump(macro, opts) do
    __MODULE__.inspect(macro, Keyword.get(opts, :dump))
  end

  ## ENUMERABLE TOOLS

  def collect(accumulator, enumerable, reducer) do
    Enum.reduce(enumerable, accumulator, &reducer.(&2, &1))
  end

  def flatten([]), do: []

  def flatten(list) when is_list(list) do
    if Enum.all?(list, &is_list/1) do
      flatten(Enum.flat_map(list, & &1))
    else
      list
    end
  end

  ## AST TOOLS

  def variable(v), do: {v, [], Elixir}

  def arrow(preimage, out) do
    {:->, [], [preimage, out]}
  end

  ### JsonPointer to function name
  @spec pointer_to_fun_name(JsonPointer.t(), keyword) :: atom
  def pointer_to_fun_name(pointer, opts) do
    # proactively stringify authorities, which might be atoms.
    opts =
      List.wrap(
        if authority = opts[:authority] do
          {:authority, "#{authority}"}
        end
      )

    pointer
    |> JsonPointer.to_uri(opts)
    |> adjust_length
    |> String.to_atom()
  end

  # a general strategy to adjust the length of a string that needs to become an atom,
  # works when the string's length is too big.  Assumes that the string is UTF-8 encoded.
  def adjust_length(string) when byte_size(string) < 255, do: string

  def adjust_length(string) do
    # take the first 25 and last 25 characters and put the base16-hashed value in the middle
    g = String.graphemes(string)
    first = Enum.take(g, 25)
    last = g |> Enum.reverse() |> Enum.take(25) |> Enum.reverse()
    middle = Base.encode16(<<:erlang.phash2(string)::32>>)
    IO.iodata_to_binary([first, "..", middle, "..", last])
  end

  @doc false
  def fun_to_path(fun) do
    fun
    |> to_string
    |> String.split("#/")
    |> tl()
    |> Enum.join()
    |> amend_path
  end

  defp amend_path(path = "/" <> _), do: path
  defp amend_path(path), do: "/" <> path

  defmacro mismatch(error_value, schema_pointer, json_pointer, opts \\ []) do
    primary = Keyword.take(binding(), ~w(error_value schema_pointer json_pointer)a)
    extras = Keyword.take(opts, ~w(reason failures matches required)a)

    quote bind_quoted: [error_params: primary ++ extras] do
      {:error, error_params}
    end
  end

  @all_types_lists [
    ~w(array boolean integer null number object string),
    # you can skip integer because number subsumes it
    ~w(array boolean null number object string)
  ]

  @spec determined(module, atom, JsonPointer.t()) :: :ok | :error | :unknown
  def determined(module, name, pointer) do
    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> determined
  end

  @spec determined(Type.json()) :: :ok | :error | :unknown
  def determined(true), do: :ok
  def determined(false), do: :error

  def determined(subschema = %{"type" => t}) do
    if Enum.sort(List.wrap(t)) in @all_types_lists do
      subschema
      |> Map.delete("type")
      |> determined()
      |> matches(true)
    else
      :unknown
    end
  end

  def determined(subschema = %{"not" => not_schema}) do
    rest =
      subschema
      |> Map.delete("not")
      |> determined

    case determined(not_schema) do
      :ok when rest === :error -> :error
      :error when rest === :ok -> :ok
      _ -> :unknown
    end
  end

  def determined(subschema = %{"allOf" => list}) do
    rest_determined =
      subschema
      |> Map.delete("allOf")
      |> determined

    list
    |> Enum.map(&determined/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_determined

      [:ok] ->
        matches(rest_determined, true)

      [:error] ->
        matches(rest_determined, false)

      _ ->
        :unknown
    end
  end

  def determined(subschema = %{"anyOf" => list}) do
    rest_determined =
      subschema
      |> Map.delete("anyOf")
      |> determined

    list
    |> Enum.map(&determined/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_determined

      [:error] ->
        matches(rest_determined, false)

      list ->
        if :ok in list do
          matches(rest_determined, true)
        else
          :unknown
        end
    end
  end

  def determined(subschema = %{"minItems" => 0}) do
    subschema
    |> Map.delete("minItems")
    |> determined
  end

  def determined(subschema = %{"minProperties" => 0}) do
    subschema
    |> Map.delete("minProperties")
    |> determined
  end

  def determined(subschema = %{"minContains" => 0}) do
    subschema
    |> Map.delete("minContains")
    |> determined
  end

  def determined(empty_map) when empty_map == %{} do
    :ok
  end

  def determined(_), do: :unknown

  defp matches(value, rest_schema) do
    case determined(rest_schema) do
      ^value -> value
      _ -> :unknown
    end
  end
end
