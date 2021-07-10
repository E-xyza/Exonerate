defmodule Exonerate.Validator do
  alias Exonerate.Compiler
  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Pointer

  @enforce_keys [:pointer, :schema]
  @initial_typemap Type.all()
  @all_types Map.keys(@initial_typemap)

  defstruct @enforce_keys ++ [
    context: nil,
    required_refs: [],
    # compile-time optimizations
    types: @initial_typemap,
    guards: []
  ]

  @type t :: %__MODULE__{
    # global state
    pointer: Pointer.t,
    schema: Type.schema,
    required_refs: [[String.t]],
    types: %{optional(Type.t) => nil | Type.type_struct},
    guards: [module]
  }

  @spec new(Type.json, Pointer.t, keyword) :: t
  defp new(schema, pointer, opts) do
    struct(%__MODULE__{schema: schema, pointer: pointer}, opts)
  end

  @spec parse(Type.json, Pointer.t, keyword) :: t
  def parse(schema, pointer, opts \\ []) do
    pointer
    |> Pointer.eval(schema)
    |> new(pointer, opts)
    |> analyze()
  end

  @validator_filters ~w(type enum const)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @spec analyze(t) :: t
  defp analyze(validator) do
    case traverse(validator) do
      bool when is_boolean(bool) -> validator
      schema when is_map(schema) ->
        # TODO: put this into its own pipeline
        validator
        |> Tools.collect(@validator_filters,
          fn
            v, filter when is_map_key(schema, filter) ->
              Filter.parse(v, @validator_modules[filter], schema) # restore the pointer location.
            v, _ -> v
          end)
        |> Tools.collect(@all_types, fn
          v = %{types: types}, type when is_map_key(types, type) ->
            %{v | types: Map.put(v.types, type, type.parse(v, traverse(v)))}
          v, _type -> v
        end)
      invalid ->
        raise ArgumentError, "#{inspect invalid} is not a valid JSONSchema"
    end
  end

  @spec jump_into(t, String.t) :: t
  @doc """
  advances the pointer in the validator prior to evaluating.
  """
  def jump_into(validator, nexthop) do
    %{validator | pointer: [nexthop | validator.pointer]}
  end

  @spec merge_into(t, t) :: t
  @doc """
  selects values to be persisted into the the "old validator" from the derived validator.
  """
  def merge_into(validator, old_validator) do
    %{old_validator | types: validator.types}
  end

  @spec compile(t) :: Macro.t
  def compile(validator = %__MODULE__{pointer: pointer, schema: schema, context: context}) do
    case Pointer.eval(pointer, schema) do
      true ->
        quote do
          defp unquote(Pointer.to_fun(pointer, context: context))(_, _), do: :ok
        end
      false ->
        quote do
          defp unquote(Pointer.to_fun(pointer, context: context))(value, path) do
            Exonerate.mismatch(value, path)
          end
        end
      object when is_map(object) ->
        build_schema(validator)
    end
  end

  def build_schema(validator = %{types: [], guards: guards}) do
    # no available types, go straight to mismatch.
    quote do
      defp unquote(to_fun(validator))(value, path) do
        Exonerate.mismatch(value, path)
      end
    end
  end

  def build_schema(validator) do
    guards = validator.guards
    |> Enum.map(&%{&1 | context: validator})
    |> Enum.map(&Compiler.compile/1)

    {funs, children} = validator.types
      |> Map.values
      |> Enum.map(&Compiler.compile/1)
      |> Enum.unzip

    quote do
      unquote_splicing(Tools.flatten(guards))
      unquote_splicing(Tools.flatten(funs))
      defp unquote(to_fun(validator))(value, path) do
        :ok
      end
      unquote_splicing(Enum.flat_map(children, &(&1)))
    end |> Tools.inspect
  end

  def to_fun(%{pointer: pointer, context: context}) do
    Pointer.to_fun(pointer, context: context)
  end

  @spec traverse(t) :: Type.json
  def traverse(validator) do
    Pointer.eval(validator.pointer, validator.schema)
  end
end
