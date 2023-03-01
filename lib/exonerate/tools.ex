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

  @spec degeneracy(module, atom, JsonPointer.t()) :: :ok | :error | :unknown
  def degeneracy(module, name, pointer) do
    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> degeneracy
  end

  @spec degeneracy(Type.json()) :: :ok | :error | :unknown
  def degeneracy(true), do: :ok
  def degeneracy(false), do: :error

  def degeneracy(subschema = %{"type" => t}) do
    if Enum.sort(List.wrap(t)) in @all_types_lists do
      subschema
      |> Map.delete("type")
      |> degeneracy()
      |> matches(true)
    else
      :unknown
    end
  end

  def degeneracy(subschema = %{"not" => not_schema}) do
    rest =
      subschema
      |> Map.delete("not")
      |> degeneracy

    case degeneracy(not_schema) do
      :ok when rest === :error -> :error
      :error when rest === :ok -> :ok
      _ -> :unknown
    end
  end

  def degeneracy(subschema = %{"allOf" => list}) do
    rest_degeneracy =
      subschema
      |> Map.delete("allOf")
      |> degeneracy

    list
    |> Enum.map(&degeneracy/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_degeneracy

      [:ok] ->
        matches(rest_degeneracy, true)

      [:error] ->
        matches(rest_degeneracy, false)

      _ ->
        :unknown
    end
  end

  def degeneracy(subschema = %{"anyOf" => list}) do
    rest_degeneracy =
      subschema
      |> Map.delete("anyOf")
      |> degeneracy

    list
    |> Enum.map(&degeneracy/1)
    |> Enum.uniq()
    |> case do
      [] ->
        rest_degeneracy

      [:error] ->
        matches(rest_degeneracy, false)

      list ->
        if :ok in list do
          matches(rest_degeneracy, true)
        else
          :unknown
        end
    end
  end

  def degeneracy(subschema = %{"minItems" => 0}) do
    subschema
    |> Map.delete("minItems")
    |> degeneracy
  end

  def degeneracy(subschema = %{"minProperties" => 0}) do
    subschema
    |> Map.delete("minProperties")
    |> degeneracy
  end

  def degeneracy(subschema = %{"minContains" => 0}) do
    subschema
    |> Map.delete("minContains")
    |> degeneracy
  end

  def degeneracy(empty_map) when empty_map == %{} do
    :ok
  end

  def degeneracy(_), do: :unknown

  defp matches(value, rest_schema) do
    case degeneracy(rest_schema) do
      ^value -> value
      _ -> :unknown
    end
  end

  # tracking related
  def drop_tracking(opts) do
    Keyword.drop(opts, [:track_properties, :track_items])
  end

  # general convenience functions
  def if(item, boolean, predicate) do
    if boolean do
      predicate.(item)
    else
      item
    end
  end
end
