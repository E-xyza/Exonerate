defmodule Exonerate.Filter do
  @moduledoc false

  # define some callbacks that all of our filter generators have to create.

  alias Exonerate.Type

  @default_types Map.new(~w(
    array
    boolean
    integer
    null
    number
    object
    string
  )a, &{&1, []})

  @enforce_keys [:path, :footer]
  defstruct @enforce_keys ++ [types: @default_types]

  @type state :: %__MODULE__{
    path: atom,
    types: %{Type.t => []},
    footer: Macro.t
  }

  @callback filter(Type.json, state) :: {[Macro.t], state}

  #################################################################################
  ## API

  @spec from_schema(Type.json, atom) :: Macro.t
  def from_schema(false, spec_path) do
    quote do
      defp unquote(spec_path)(value, path) do
        Exonerate.mismatch(value, path)
      end
    end
  end

  @spec from_schema(Type.json, atom) :: Macro.t
  def from_schema(schema, spec_path) do
    alias Exonerate.Filter.AllOf
    alias Exonerate.Filter.AnyOf
    alias Exonerate.Filter.Array
    alias Exonerate.Filter.Const
    alias Exonerate.Filter.Enum
    alias Exonerate.Filter.Integer
    alias Exonerate.Filter.Not
    alias Exonerate.Filter.Number
    alias Exonerate.Filter.Object
    alias Exonerate.Filter.OneOf
    alias Exonerate.Filter.String
    alias Exonerate.Filter.Type

    default_footer = &quote do
      defp unquote(&1)(_value, _path), do: :ok
    end

    {filter_ast, state} = Elixir.Enum.flat_map_reduce(
      [Const, Enum, Type, AllOf, AnyOf, OneOf, Not, String, Number, Integer, Object, Array],
      %__MODULE__{
        path: spec_path,
        footer: default_footer
      },
      fn module, state ->
        module.filter(schema, state)
      end)

    fallthrough = case state.types do
      map when map == %{} -> :ok
      _ -> state.footer.(state.path)
    end

    q = quote do
      unquote_splicing(filter_ast)
      unquote(fallthrough)
    end

    if Atom.to_string(spec_path) =~ "test6" do
      q |> Macro.to_string |> IO.puts
    end

    q
  end

  #################################################################################
  ## helper functions

  @spec filter_type(state, Type.json) :: state
  def filter_type(state, value) do
    %{state | types: Map.take(state.types, [Type.of(value)])}
  end

  @spec filter_types(state, [Type.json]) :: state
  def filter_types(state, values) do
    allowed = Enum.map(values, &Type.of/1)
    %{state | types: Map.take(state.types, allowed)}
  end

  @spec drop_type(state, Type.t) :: state
  def drop_type(state, type) do
    %{state | types: Map.delete(state.types, type)}
  end
end
