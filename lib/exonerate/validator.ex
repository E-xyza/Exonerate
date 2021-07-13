defmodule Exonerate.Validator do
  alias Exonerate.Compiler
  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Pointer
  alias Exonerate.Ref
  alias Exonerate.Registry

  @enforce_keys [:pointer, :schema, :authority]
  @initial_typemap Type.all()
  @all_types Map.keys(@initial_typemap)

  defstruct @enforce_keys ++ [
    required_refs: [],
    # compile-time optimizations
    types: @initial_typemap,
    guards: [],
    combining: [],
    children: [],
    then: false,
    else: false,
    needed_by: nil
  ]

  @type t :: %__MODULE__{
    authority: String.t,
    # global state
    pointer: Pointer.t,
    schema: Type.schema,
    required_refs: [[String.t]],
    types: %{optional(Type.t) => nil | Type.type_struct},
    guards: [module],
    combining: [module],
    children: [module],
    then: boolean,
    else: boolean,
    needed_by: [%{pointer: Pointer.t, fun: atom}]
  } | Ref.t

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

  # if must come after "then" and "else" in processing order.
  @validator_filters ~w(type enum const $ref allOf not anyOf oneOf then else if)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @spec analyze(t) :: t
  defp analyze(validator! = %__MODULE__{}) do
    validator! = register(validator!)

    case traverse(validator!) do
      # TODO: break this out into its own function.
      ref = %Ref{} -> ref
      bool when is_boolean(bool) -> validator!
      schema when is_map(schema) ->
        # TODO: put this into its own function
        validator!
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
  defp analyze(ref = %Ref{}), do: ref

  defp register(validator) do
    case Registry.register(validator.schema, validator.pointer, to_fun(validator))  do
      :ok -> validator
      {:exists, target} ->
        %Ref{pointer: validator.pointer, authority: validator.authority, target: target}
      {:needed, needed_by} ->
        # on re-entrant registry requests we don't want to make another function.
        if needed_by == to_fun(validator) do
          validator
        else
          %{validator | needed_by: needed_by}
        end
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
          unquote_splicing(build_needed(validator))
        end
      false ->
        quote do
          defp unquote(Pointer.to_fun(pointer, authority: authority))(value, path) do
            Exonerate.mismatch(value, path)
          end
          unquote_splicing(build_needed(validator))
        end
      object when is_map(object) ->
        build_schema(validator)
    end
  end
  def compile(ref = %Ref{}) do
    # TODO: break this out into its own compiler protocol impl.
    quote do
      defp unquote(Pointer.to_fun(ref.pointer, authority: ref.authority))(value, path) do
        unquote(ref.target)(value, path)
      end
    end
  end

  alias Exonerate.Filter.Format
  def build_schema(validator = %{types: types}) when types == %{String => %{filters: [%Format{format: "binary"}]}} do
    # no available types, go straight to mismatch.
    quote do
      defp unquote(to_fun(validator))(value, path) do
        Exonerate.mismatch(value, path)
      end
      unquote_splicing(build_needed(validator))
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

    combining = combining(validator, quote do value end, quote do path end)

    quote do
      unquote_splicing(Tools.flatten(guards))
      unquote_splicing(Tools.flatten(funs))
      defp unquote(to_fun(validator))(value, path) do
        unquote_splicing(combining)
      end
      unquote_splicing(Enum.flat_map(children, &(&1)))
      unquote_splicing(build_needed(validator))
    end
  end

  defp build_needed(validator = %__MODULE__{needed_by: nil}), do: []
  defp build_needed(validator = %__MODULE__{needed_by: what}) do
    [quote do
      defp unquote(what)(value, path) do
        unquote(to_fun(validator))(value, path)
      end
    end]
  end

  def combining(%{combining: []}, _, _) do
    [:ok]
  end
  def combining(validator, value_ast, path_ast) do
    Enum.map(validator.combining, fn filter = %module{} ->
      module.combining(filter, value_ast, path_ast)
    end)
  end

  def to_fun(%{pointer: pointer, authority: authority}) do
    Pointer.to_fun(pointer, authority: authority)
  end

  @spec traverse(t) :: Type.json
  def traverse(validator = %__MODULE__{}) do
    Pointer.eval(validator.pointer, validator.schema)
  end
  def traverse(ref = %Ref{}), do: ref
end
