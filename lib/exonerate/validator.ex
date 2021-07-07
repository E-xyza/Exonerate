defmodule Exonerate.Validator do
  alias Exonerate.Filter
  alias Exonerate.Type
  alias Exonerate.Pointer

  @enforce_keys [:pointer, :schema]
  @all_types MapSet.new(Type.all())

  defstruct @enforce_keys ++ [
    context: nil,
    required_refs: [],
    # compile-time optimizations
    types: @all_types
#    guards: [],
#    calls: %{},
#    collection_calls: %{},
#    children: [],
#    accumulator: %{},
#    post_accumulate: [],
#    types: @default_types
  ]

  @type t :: %__MODULE__{
    # global state
    pointer: Pointer.t,
    schema: Type.schema,
    required_refs: [[String.t]],
    types: MapSet.t(Type.t)
    # local state
#    path: [String.t],
#    guards: [Macro.t],
#    calls: %{(Type.t | :then | :else | :all) => [atom]},
#    collection_calls: %{(:array | :object) => [atom]},
#    children: [Macro.t],
#    accumulator: %{atom => boolean},
#    post_accumulate: [atom],
#    # compile-time optimization
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

  @validator_filters ~w(type)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @spec analyze(t) :: t
  defp analyze(validator) do
    case traverse(validator) do
      bool when is_boolean(bool) -> validator
      schema when is_map(schema) ->
        Enum.reduce(
          @validator_filters,
          validator,
          fn
            filter, v when is_map_key(schema, filter) ->
              # restore the pointer location.
              v
              |> jump_into(filter)
              |> @validator_modules[filter].analyze()
              |> merge_into(v)
            _, v -> v
          end)
      invalid ->
        raise ArgumentError, "#{inspect invalid} is not a valid JSONSchema"
    end
  end

  @spec traverse(t) :: Type.json
  def traverse(validator) do
    Pointer.eval(validator.pointer, validator.schema)
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
          def unquote(Pointer.to_fun(pointer, context: context))(_, _), do: :ok
        end
      false ->
        quote do
          def unquote(Pointer.to_fun(pointer, context: context))(value, path) do
            Exonerate.mismatch(value, path)
          end
        end
      object when is_map(object) ->
        build_schema(validator)
    end
  end

  def build_schema(validator = %{types: @all_types}) do
    # for now.
    quote do
      def unquote(to_fun(validator))(_, _), do: :ok
    end
  end

  def build_schema(validator = %{types: []}) do
    quote do
      def unquote(to_fun(validator))(value, path) do
        Exonerate.mismatch(value, path)
      end
    end
  end

  def build_schema(validator) do
    funs = Enum.map(
      validator.types,
      &(&1.compile(validator)))

    quote do
      unquote_splicing(funs)
      def unquote(to_fun(validator))(value, path) do
        Exonerate.mismatch(value, path, guard: "type")
      end
    end
  end

  def to_fun(%{pointer: pointer, context: context}) do
    Pointer.to_fun(pointer, context: context)
  end

  @reserved_keys ~w($schema $id title description default examples $defs)

end
