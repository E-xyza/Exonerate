defmodule Exonerate.Validator do
  alias Exonerate.Compiler
  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Pointer

  @enforce_keys [:pointer, :schema, :authority]
  @initial_typemap Type.all()
  @all_types Map.keys(@initial_typemap)

  defstruct @enforce_keys ++ [
    required_refs: [],
    # compile-time optimizations
    types: @initial_typemap,
    guards: [],
    distribute: [],
    children: []
  ]

  @type t :: %__MODULE__{
    authority: String.t,
    # global state
    pointer: Pointer.t,
    schema: Type.schema,
    required_refs: [[String.t]],
    types: %{optional(Type.t) => nil | Type.type_struct},
    guards: [module],
    distribute: [module],
    children: [module]
  }

  @spec new(Type.json, Pointer.t, keyword) :: t
  defp new(schema, pointer, opts) do
    struct(%__MODULE__{schema: schema, pointer: pointer, authority: opts[:authority] || ""}, opts)
  end

  @spec parse(Type.json, Pointer.t, keyword) :: t
  def parse(schema, pointer, opts \\ []) do
    schema
    |> new(pointer, opts)
    |> analyze()
  end

  @validator_filters ~w(type enum const allOf not anyOf oneOf)
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
  def jump_into(validator, nexthop, should_clear \\ false) do
    clear(%{validator | pointer: [nexthop | validator.pointer]}, should_clear)
  end

  defp clear(validator, false), do: validator
  defp clear(validator, true), do: %{validator | types: @initial_typemap, guards: []}

  @spec merge_into(t, t) :: t
  @doc """
  selects values to be persisted into the the "old validator" from the derived validator.
  """
  def merge_into(validator, old_validator) do
    %{old_validator | types: validator.types}
  end

  @spec compile(t) :: Macro.t
  def compile(validator = %__MODULE__{pointer: pointer, schema: schema, authority: authority}) do
    case Pointer.eval(pointer, schema) do
      true ->
        quote do
          defp unquote(Pointer.to_fun(pointer, authority: authority))(_, _), do: :ok
        end
      false ->
        quote do
          defp unquote(Pointer.to_fun(pointer, authority: authority))(value, path) do
            Exonerate.mismatch(value, path)
          end
        end
      object when is_map(object) ->
        build_schema(validator)
    end |> Tools.inspect(validator.authority == "minContains_2")
  end

  def build_schema(validator = %{types: types}) when types == %{} do
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

    {funs, type_children} = validator.types
      |> Map.values
      |> Enum.map(&Compiler.compile/1)
      |> Enum.unzip

    direct_children = Enum.map(validator.children, &Compiler.compile/1)

    children = type_children ++ direct_children

    distributed = distribute(validator, quote do value end, quote do path end)

    quote do
      unquote_splicing(Tools.flatten(guards))
      unquote_splicing(Tools.flatten(funs))
      defp unquote(to_fun(validator))(value, path) do
        unquote_splicing(distributed)
      end
      unquote_splicing(Enum.flat_map(children, &(&1)))
    end
  end

  def distribute(%{distribute: []}, _, _) do
    [:ok]
  end
  def distribute(validator, value_ast, path_ast) do
    Enum.map(validator.distribute, fn filter = %module{} ->
      module.distribute(filter, value_ast, path_ast)
    end)
  end

  def to_fun(%{pointer: pointer, authority: authority}) do
    Pointer.to_fun(pointer, authority: authority)
  end

  @spec traverse(t) :: Type.json
  def traverse(validator) do
    Pointer.eval(validator.pointer, validator.schema)
  end
end
