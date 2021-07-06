defmodule Exonerate.Validator do
  alias Exonerate.Type
  alias Exonerate.Pointer

  @enforce_keys [:pointer, :schema]

  defstruct @enforce_keys ++ [
    context: nil,
    required_refs: [],
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
    # local state
#    path: [String.t],
#    guards: [Macro.t],
#    calls: %{(Type.t | :then | :else | :all) => [atom]},
#    collection_calls: %{(:array | :object) => [atom]},
#    children: [Macro.t],
#    accumulator: %{atom => boolean},
#    post_accumulate: [atom],
#    # compile-time optimization
#    types: %{Type.t => []},
  }

  @spec new(Type.json, Pointer.t) :: t
  defp new(schema, pointer) do
    %__MODULE__{schema: schema, pointer: pointer}
  end

  @spec parse(Type.json, Pointer.t, keyword) :: t
  def parse(schema, pointer, opts \\ []) do
    pointer
    |> Pointer.eval(schema)
    |> analyze(schema, pointer)
    |> struct(opts)
  end

  @spec analyze(Type.schema, Type.json, Pointer.t) :: t
  defp analyze(bool, schema, path) when is_boolean(bool) do
    new(schema, path)
  end
  defp analyze(inner_schema, schema, path) when is_map(inner_schema) do
    new(schema, path)
  end
  defp analyze(invalid, _, _) do
    raise ArgumentError, "#{inspect invalid} is not a valid JSONSchema"
  end

  @spec compile(t) :: Macro.t
  def compile(%__MODULE__{pointer: pointer, schema: schema, context: context}) do
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
        quote do end
    end
  end


  @reserved_keys ~w($schema $id title description default examples $defs)

  def from_schema(false, validation) do
    fun = Exonerate.path_to_call(validation)
    quote do
      defp unquote(fun)(value, path) do
        Exonerate.mismatch(value, path)
      end
    end
  end
  def from_schema(schema, validation = %__MODULE__{}) when is_map(schema) do
    fun = Exonerate.path_to_call(validation)

    validation = schema
    |> Enum.reject(&(elem(&1, 0) in @reserved_keys))
    |> Enum.sort(&tag_reorder/2)
    |> Enum.reduce(validation, fn
      {k, v}, so_far ->
        filter_for(k).append_filter(v, so_far)
    end)

    active_types = Map.keys(validation.types)

    all_calls = validation.calls[:all]
    |> List.wrap
    |> Enum.reverse
    |> Enum.map(&quote do unquote(&1)(value, path) end)

    {calls!, types_left} = Enum.flat_map_reduce(active_types, active_types, fn type, types_left ->
      if is_map_key(validation.calls, type) or
         is_map_key(validation.collection_calls, type) do
        guard = Exonerate.Type.guard(type)
        type_calls = validation.calls[type]
        |> List.wrap
        |> Enum.reverse
        |> Enum.map(&quote do unquote(&1)(value, path) end)

        collection_calls = validation.collection_calls[type]
        |> List.wrap
        |> Enum.reverse
        |> Enum.map(&quote do acc = unquote(&1)(unit, acc, path) end)

        collection_validation = case type do
          _ when collection_calls == [] -> quote do end
          :object ->
            quote do
              Enum.each(value, fn unit ->
                acc = false
                unquote_splicing(collection_calls)
                acc
              end)
            end
          :array ->
            exit_early = Map.has_key?(schema, "maxItems") or Map.has_key?(schema, "maxContains")

            post_accumulate =
              Enum.map(validation.post_accumulate, &quote do unquote(&1)(acc, value, path) end)

            quote do
              require Exonerate.Filter

              acc =
                Exonerate.Filter.wrap(
                  unquote(exit_early),
                  value
                  |> Enum.with_index
                  |> Enum.reduce(unquote(Macro.escape(validation.accumulator)), fn unit, acc ->
                    unquote_splicing(collection_calls)
                    acc
                  end), value, path)

              unquote_splicing(post_accumulate)
            end
        end

        {[quote do
           defp unquote(fun)(value, path) when unquote(guard)(value) do
             unquote_splicing(type_calls ++ all_calls)
             unquote(collection_validation)
             :ok
           end
         end],
         types_left -- [type]}
      else
        {[], types_left}
      end
    end)

    calls! = cond do
      types_left == [] -> calls!
      all_calls == [] -> calls! ++ [quote do
        defp unquote(fun)(_value, _path), do: :ok
      end]
      true -> calls! ++ [quote do
        defp unquote(fun)(value, path) do
          unquote_splicing(all_calls)
        end
      end]
    end

    quote do
      unquote_splicing(validation.guards)
      unquote_splicing(calls!)
      unquote_splicing(validation.children)
    end
  end

  defp tag_reorder(a, a), do: true
  # type, enum to the top;
  # items, if, maxContains, minContains, additionalItems and additionalProperties to the bottom
  defp tag_reorder({"type", _}, _), do: true
  defp tag_reorder(_, {"type", _}), do: false
  defp tag_reorder({"enum", _}, _), do: true
  defp tag_reorder(_, {"enum", _}), do: false
  #--------------------------------------------------------------------------------------------
  defp tag_reorder({"items", _}, _), do: false
  defp tag_reorder(_, {"items", _}), do: true
  defp tag_reorder({"if", _}, _), do: false
  defp tag_reorder(_, {"if", _}), do: true
  defp tag_reorder({"maxContains", _}, _), do: false
  defp tag_reorder(_, {"maxContains", _}), do: true
  defp tag_reorder({"minContains", _}, _), do: false
  defp tag_reorder(_, {"minContains", _}), do: true
  defp tag_reorder({"additionalItems", _}, _), do: false
  defp tag_reorder(_, {"additionalItems", _}), do: true
  defp tag_reorder({"additionalProperties", _}, _), do: false
  defp tag_reorder(_, {"additionalProperties", _}), do: true
  defp tag_reorder({"unevaluatedItems", _}, _), do: false
  defp tag_reorder(_, {"unevaluatedItems", _}), do: true
  defp tag_reorder({"unevaluatedProperties", _}, _), do: false
  defp tag_reorder(_, {"unevaluatedProperties", _}), do: true
  defp tag_reorder(a, b), do: a >= b

  defp filter_for("$ref"), do: Exonerate.Filter.Ref
  defp filter_for(key) do
    Module.concat(Exonerate.Filter, capitalize(key))
  end

  defp capitalize(<<f::binary-size(1), rest::binary>>) do
    String.upcase(f) <> rest
  end
end
