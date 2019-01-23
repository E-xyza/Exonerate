defmodule Exonerate.Macro do
  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Macro.BuildCond

  @type condlist :: [BuildCond.condclause]
  @type defblock :: {:def, any, any}

  defmacro defschema([{method, json} | _opts]) do

    code = json
    |> maybe_desigil
    |> Jason.decode!
    |> matcher(method)

    quote do
      unquote_splicing(code)
    end
  end

  @all_types ["string", "number", "boolean", "null", "object", "array"]

  @spec matcher(any, any)::[defblock | {:__block__, any, any}]
  def matcher(true, method), do: always_matches(method)
  def matcher(false, method), do: never_matches(method)
  # metadata things
  def matcher(spec = %{"title" => title}, method), do: set_title(spec, title, method)
  def matcher(spec = %{"description" => desc}, method), do: set_description(spec, desc, method)
  def matcher(spec = %{"default" => default}, method), do: set_default(spec, default, method)
  def matcher(spec = %{"examples" => examples}, method), do: set_examples(spec, examples, method)
  def matcher(spec = %{"$schema" => schema}, method), do: set_schema(spec, schema, method)
  def matcher(spec = %{"$id" => id}, method), do: set_id(spec, id, method)
  # match enums and consts
  def matcher(spec = %{"enum" => elist}, method), do: match_enum(spec, elist, method)
  def matcher(spec = %{"const" => const}, method), do: match_const(spec, const, method)
  # match combining elements
  def matcher(spec = %{"allOf" => clist}, method), do: match_allof(spec, clist, method)
  def matcher(spec = %{"anyOf" => clist}, method), do: match_anyof(spec, clist, method)
  def matcher(spec = %{"oneOf" => clist}, method), do: match_oneof(spec, clist, method)
  def matcher(spec = %{"not" => inv}, method), do: match_not(spec, inv, method)
  # type matching things
  def matcher(spec, method) when spec == %{}, do: always_matches(method)
  def matcher(spec = %{"type" => "string"}, method), do: match_string(spec, method)
  def matcher(spec = %{"type" => "integer"}, method), do: match_integer(spec, method)
  def matcher(spec = %{"type" => "number"}, method), do: match_number(spec, method)
  def matcher(spec = %{"type" => "boolean"}, method), do: match_boolean(spec, method)
  def matcher(spec = %{"type" => "null"}, method), do: match_null(spec, method)
  def matcher(spec = %{"type" => "object"}, method), do: match_object(spec, method)
  def matcher(spec = %{"type" => "array"}, method), do: match_array(spec, method)
  def matcher(spec = %{"type" => list}, method) when is_list(list), do: match_list(spec, list, method)
  def matcher(spec, method), do: match_list(spec, @all_types, method)

  @spec always_matches(atom) :: [defblock]
  defp always_matches(method) do
    [quote do
      def unquote(method)(_val) do
        :ok
      end
    end]
  end

  @spec never_matches(atom) :: [defblock]
  defp never_matches(method) do
    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
      end
    end]
  end

  @spec set_title(map, String.t, atom) :: [defblock]
  def set_title(spec, title, method) do
    rest = spec
    |> Map.delete("title")
    |> matcher(method)

    [quote do
      def unquote(method)(:title), do: unquote(title)
    end | rest]
  end

  @spec set_description(map, String.t, atom) :: [defblock]
  def set_description(spec, description, method) do
    rest = spec
    |> Map.delete("description")
    |> matcher(method)

    [quote do
      def unquote(method)(:description), do: unquote(description)
    end | rest]
  end

  @spec set_default(map, any, atom) :: [defblock]
  def set_default(spec, default, method) do
    rest = spec
    |> Map.delete("default")
    |> matcher(method)

    [quote do
      def unquote(method)(:default), do: unquote(default)
    end | rest]
  end

  @spec set_examples(map, [any], atom) :: [defblock]
  def set_examples(spec, examples, method) do
    rest = spec
    |> Map.delete("examples")
    |> matcher(method)

    [quote do
      def unquote(method)(:examples), do: unquote(examples)
    end | rest]
  end

  @spec set_schema(map, String.t, atom) :: [defblock]
  def set_schema(map, schema, module) do
    rest = map
    |> Map.delete("$schema")
    |> matcher(module)

    [quote do
       def unquote(module)(:schema), do: unquote(schema)
     end | rest]
  end

  @spec set_id(map, String.t, atom) :: [defblock]
  def set_id(map, id, module) do
    rest = map
    |> Map.delete("$id")
    |> matcher(module)

    [quote do
      def unquote(module)(:id), do: unquote(id)
     end | rest]
  end

  @spec match_allof(map, list(any), atom) :: [defblock]
  defp match_allof(base_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    submethod_name = &generate_submethod(method, "_allof_" <> inspect &1)
    base_submethod = generate_submethod(method, "_allof_base")

    comb_list = [base_submethod | Enum.map(idx_range, submethod_name)]

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        submethod = submethod_name.(idx)
        matcher(spec, submethod)
      end
    )

    base_dependency = base_spec
    |> Map.delete("allOf")
    |> matcher(base_submethod)

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_all(
          __MODULE__,
          unquote(comb_list),
          [val],
          unquote(method))
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_anyof(map, list(any), atom) :: [defblock]
  defp match_anyof(base_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    submethod_name = &generate_submethod(method, "_anyof_" <> inspect &1)
    base_submethod = generate_submethod(method, "_allof_base")

    comb_list = Enum.map(idx_range, submethod_name)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        submethod = submethod_name.(idx)
        matcher(spec, submethod)
      end
    )

    base_dependency = base_spec
    |> Map.delete("anyOf")
    |> matcher(base_submethod)

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_any(
          __MODULE__,
          unquote(comb_list),
          unquote(base_submethod),
          [val],
          unquote(method))
      end
    end]
    ++ base_dependency
    ++ dependencies
  end

  @spec match_oneof(map, list(any), atom) :: [defblock]
  defp match_oneof(_spec, spec_list, method) do

    idx_range = 0..(Enum.count(spec_list) - 1)

    submethod_name = &generate_submethod(method, "_oneof_" <> inspect &1)

    comb_list = Enum.map(idx_range, submethod_name)

    dependencies = spec_list
    |> Enum.with_index
    |> Enum.map(
      fn {spec, idx} ->
        submethod = submethod_name.(idx)
        matcher(spec, submethod)
      end
    )

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.reduce_one(
          __MODULE__,
          unquote(comb_list),
          [val],
          unquote(method))
      end
    end] ++ dependencies
  end

  @spec match_not(map, any, atom) :: [defblock]
  defp match_not(_spec, inv_spec, method) do

    not_method = generate_submethod(method, "_not")

    [quote do
      def unquote(method)(val) do
        Exonerate.Macro.apply_not(
          __MODULE__,
          unquote(not_method),
          [val])
      end
    end] ++ matcher(inv_spec, not_method)
  end

  @spec match_enum(map, list(any), atom) :: [defblock]
  defp match_enum(spec, enum_list, method) do
    esc_list = Macro.escape(enum_list)

    enum_submethod = generate_submethod(method, "_enclosing")

    [quote do
      def unquote(method)(val) do
        if val in unquote(esc_list) do
          unquote(enum_submethod)(val)
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("enum")
     |> matcher(enum_submethod))
  end

  @spec match_const(map, any, atom) :: [defblock]
  defp match_const(spec, const, method) do
    const_val = Macro.escape(const)

    const_submethod = generate_submethod(method, "_enclosing")

    [quote do
      def unquote(method)(val) do
        if val == unquote(const_val) do
          unquote(const_submethod)(val)
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(method), val)
        end
      end
    end] ++
    (spec
     |> Map.delete("const")
     |> matcher(const_submethod))
  end

  @spec match_string(map, atom, boolean) :: [defblock]
  defp match_string(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_string_cond(method)
    |> BuildCond.build

    # TODO: make length value only appear if we have a length check.

    str_match = quote do
      def unquote(method)(val) when is_binary(val) do
        length = String.length(val)
        unquote(cond_stmt)
      end
    end

    if terminal do
      [str_match | never_matches(method)]
    else
      [str_match]
    end
  end

  @spec match_integer(map, atom, boolean) :: [defblock]
  defp match_integer(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_integer_cond(method)
    |> BuildCond.build

    int_match = quote do
      def unquote(method)(val) when is_integer(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [int_match | never_matches(method)]
    else
      [int_match]
    end
  end

  @spec match_number(map, atom, boolean) :: [defblock]
  defp match_number(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_number_cond(method)
    |> BuildCond.build

    num_match = quote do
      def unquote(method)(val) when is_number(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [num_match | never_matches(method)]
    else
      [num_match]
    end
  end

  @spec match_boolean(map, atom, boolean) :: [defblock]
  defp match_boolean(_spec, method, terminal \\ true) do

    bool_match = quote do
      def unquote(method)(val) when is_boolean(val) do
        :ok
      end
    end

    if terminal do
      [bool_match | never_matches(method)]
    else
      [bool_match]
    end
  end

  @spec match_null(map, atom, boolean) :: [defblock]
  defp match_null(_spec, method, terminal \\ true) do

    null_match = quote do
      def unquote(method)(val) when is_nil(val) do
        :ok
      end
    end

    if terminal do
      [null_match | never_matches(method)]
    else
      [null_match]
    end
  end

  @spec match_object(map, atom, boolean) :: [defblock]
  defp match_object(spec, method, terminal \\ true) do

    # build the conditional statement that guards on the object
    cond_stmt = spec
    |> build_object_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the object type
    dependencies = build_object_deps(spec, method)

    obj_match = quote do
      def unquote(method)(val) when is_map(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [obj_match | never_matches(method)] ++ dependencies
    else
      [obj_match] ++ dependencies
    end
  end

  @spec match_array(map, atom, boolean) :: [defblock]
  defp match_array(spec, method, terminal \\ true) do

    cond_stmt = spec
    |> build_array_cond(method)
    |> BuildCond.build

    # build the extra dependencies on the array type
    dependencies = build_array_deps(spec, method)

    arr_match = quote do
      def unquote(method)(val) when is_list(val) do
        unquote(cond_stmt)
      end
    end

    if terminal do
      [arr_match | never_matches(method)] ++ dependencies
    else
      [arr_match] ++ dependencies
    end
  end

  @spec match_list(map, list, atom) :: [defblock]
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
  defp match_list(spec, ["object" | tail], method) do
    head_code = match_object(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["array" | tail], method) do
    head_code = match_array(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["integer" | tail], method) do
    head_code = match_integer(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["boolean" | tail], method) do
    head_code = match_boolean(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end
  defp match_list(spec, ["null" | tail], method) do
    head_code = match_null(spec, method, false)
    tail_code = match_list(spec, tail, method)
    head_code ++ tail_code
  end

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(any), do: any

  @spec mismatch(module, atom, any) :: {:mismatch, {module, atom, [any]}}
  def mismatch(m, f, a) do
    {:mismatch, {m, f, [a]}}
  end

  @spec build_string_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering strings based on their jsonschema
    parameters
  """
  def build_string_cond(spec = %{"maxLength" => length}, method) do
    [
      {
        quote do length > unquote(length) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maxLength")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(spec = %{"minLength" => length}, method) do
    [
      {
        quote do length < unquote(length) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minLength")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(spec = %{"pattern" => patt}, method) do
    [
      {
        quote do !(Regex.match?(sigil_r(<<unquote(patt)>>, ''), val)) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("pattern")
      |> build_string_cond(method)
    ]
  end
  def build_string_cond(_spec, _method), do: []

  @spec build_integer_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering integers based on their jsonschema
    parameters
  """
  def build_integer_cond(spec = %{"multipleOf" => base}, method) do
    [
      {
        quote do rem(val, unquote(base)) != 0 end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("multipleOf")
      |> build_integer_cond(method)
    ]
  end
  def build_integer_cond(spec, module), do: build_number_cond(spec, module)

  @spec build_number_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering numbers based on their jsonschema
    parameters
  """
  def build_number_cond(spec = %{"multipleOf" => base}, method) do
    [
      #disallow multipleOf on non-integer values
      {
        quote do !is_integer(val) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      },
      {
        quote do rem(val, unquote(base)) != 0 end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("multipleOf")
      |> build_integer_cond(method)
    ]
  end
  def build_number_cond(spec = %{"minimum" => cmp}, method) do
    [
      {
        quote do val < unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("minimum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"exclusiveMinimum" => cmp}, method) do
    [
      {
        quote do val <= unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMinimum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"maximum" => cmp}, method) do
    [
      {
        quote do val > unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("maximum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(spec = %{"exclusiveMaximum" => cmp}, method) do
    [
      {
        quote do val >= unquote(cmp) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      | spec
      |> Map.delete("exclusiveMaximum")
      |> build_number_cond(method)
    ]
  end
  def build_number_cond(_spec, _method), do: []

  @spec build_object_cond(Exonerate.schema, atom) :: condlist
  @doc """
    builds the conditional structure for filtering objects based on their jsonschema
    parameters
  """
  def build_object_cond(spec = %{"additionalProperties" => _, "patternProperties" => patts}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end

    regexes = patts
    |> Map.keys
    |> Enum.map(fn v -> quote do sigil_r(<<unquote(v)>>,'') end end)

    ap_method = generate_submethod(method, "additional_properties")

    [{
      quote do
        parse_additional = Exonerate.Macro.check_additional_properties(
                    val,
                    unquote(props),
                    unquote(regexes),
                    __MODULE__,
                    unquote(ap_method))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.drop(["additionalProperties"])
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.map(fn {{k, _v}, idx} ->
      patt_method = generate_submethod(method, "pattern_#{idx}")
      {
        quote do
          parse_pattern_prop = Exonerate.Macro.check_pattern_properties(
            val,
            sigil_r(<<unquote(k)>>, ''),
            __MODULE__,
            unquote(patt_method)
          )
        end,
        quote do
          parse_pattern_prop
        end
      }
    end)) ++
    (spec
    |> Map.delete("patternProperties")
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"dependencies" => dobj}, method) do
    Enum.map(dobj, fn {k, _v} ->
      dep_method = generate_submethod(method, k <> "_dependency")
      {
        quote do
          parse_prop_dep = Exonerate.Macro.check_property_dependency(
            val,
            unquote(k),
            __MODULE__,
            unquote(dep_method)
          )
        end,
        quote do
          parse_prop_dep
        end
      }
    end) ++
    (spec
    |> Map.delete("dependencies")
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"minProperties" => min}, method) do
    [{
      quote do
        Enum.count(val) < unquote(min)
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("minProperties")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"maxProperties" => max}, method) do
    [{
      quote do
        Enum.count(val) > unquote(max)
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("maxProperties")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"required" => plist}, method) do
    [{
      quote do
        ! Enum.all?(unquote(plist), &Map.has_key?(val, &1))
      end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("required")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"propertyNames" => true}, method) do
    # true potentially matches anything, so let's not add any conditionals.
    spec
    |> Map.delete("propertyNames")
    |> build_object_cond(method)
  end
  def build_object_cond(spec = %{"propertyNames" => false}, method) do
    #false matches nothing but empty object, so add a very tight conditional.
    [{
      quote do val != %{} end,
      quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"propertyNames" => _}, method) do
    pn_method = generate_submethod(method, "property_names")
    [{
      quote do
        parse_properties = Exonerate.Macro.check_property_names(
          val,
          __MODULE__,
          unquote(pn_method)
        )
      end,
      quote do parse_properties end
    }
    | spec
    |> Map.delete("propertyNames")
    |> build_object_cond(method)
    ]
  end
  def build_object_cond(spec = %{"additionalProperties" => _}, method) do
    props = if spec["properties"] do
      Map.keys(spec["properties"])
    else
      []
    end
    ap_method = generate_submethod(method, "additional_properties")
    [{
      quote do
        parse_additional = Exonerate.Macro.check_additional_properties(
                    val,
                    unquote(props),
                    __MODULE__,
                    unquote(ap_method))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalProperties")
    |> build_object_cond(method))
  end
  def build_object_cond(spec = %{"properties" => pobj}, method) do
    Enum.map(pobj, fn {k, _v} ->
      new_method = generate_submethod(method, k)
      {
        quote do
          parse_recurse = Exonerate.Macro.check_property(
            val[unquote(k)],
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
    end) ++
    (spec
    |> Map.delete("properties")
    |> build_object_cond(method))
  end
  def build_object_cond(_spec, _method), do: []

  def build_array_cond(spec = %{"additionalItems" => _props, "items" => parr}, method) when is_list(parr) do
    #this only gets triggered when we have a tuple list.
    ap_method = generate_submethod(method, "additional_items")
    length = Enum.count(parr)
    [{
      quote do
        parse_additional = Exonerate.Macro.check_additional_array(
                    val,
                    unquote(length),
                    __MODULE__,
                    unquote(ap_method))
      end,
      quote do parse_additional end
    }] ++
    (spec
    |> Map.delete("additionalItems")
    |> build_array_cond(method))
  end
  def build_array_cond(spec = %{"items" => parr}, method) when is_list(parr) do
    for idx <- 0..(Enum.count(parr) - 1) do
      new_method = generate_submethod(method, "item_#{idx}")
      {
        quote do
          parse_recurse = Exonerate.Macro.check_tuple(
            val,
            unquote(idx),
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do
          parse_recurse
        end
      }
    end
    ++
    (spec
      |> Map.delete("items")
      |> build_array_cond(method))
  end
  def build_array_cond(spec = %{"items" => _pobj}, method) do
    new_method = generate_submethod(method, "items")
    [
      {
        quote do
          parse_recurse = Exonerate.Macro.check_items(
            val,
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("items")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"contains" => _pobj}, method) do
    new_method = generate_submethod(method, "contains")
    [
      {
        quote do
          parse_recurse = Exonerate.Macro.check_contains(
            val,
            __MODULE__,
            unquote(new_method)
          )
        end,
        quote do parse_recurse end
      }
      |
      spec
      |> Map.delete("contains")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"minItems" => items}, method) do
    [
      {
        quote do Enum.count(val) < unquote(items) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("minItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"maxItems" => items}, method) do
    [
      {
        quote do Enum.count(val) > unquote(items) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("maxItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(spec = %{"uniqueItems" => true}, method) do
    [
      {
        quote do Exonerate.Macro.contains_duplicate?(val) end,
        quote do Exonerate.Macro.mismatch(__MODULE__, unquote(method), val) end
      }
      |
      spec
      |> Map.delete("uniqueItems")
      |> build_array_cond(method)
    ]
  end
  def build_array_cond(_spec, _method), do: []


  @spec build_object_deps(Exonerate.schema, atom) :: [defblock]
  def build_object_deps(spec = %{"patternProperties" => pobj}, method) do
    (pobj
    |> Enum.with_index
    |> Enum.flat_map(fn {{_k, v}, idx} ->
      patt_prop(v, idx, method)
    end)) ++
    build_object_deps(Map.delete(spec, "patternProperties"), method)
  end
  def build_object_deps(spec = %{"properties" => pobj}, method) do
    Enum.flat_map(pobj, &object_dep(&1, method)) ++
    build_object_deps(Map.delete(spec, "properties"), method)
  end
  def build_object_deps(spec = %{"propertyNames" => pobj}, method) when is_map(pobj) do
    obj_string = Map.put(pobj, "type", "string")
    object_dep({"property_names", obj_string}, method) ++
    build_object_deps(Map.delete(spec, "propertyNames"), method)
  end
  def build_object_deps(spec = %{"additionalProperties" => pobj}, method) do
    object_dep({"additional_properties", pobj}, method) ++
    build_object_deps(Map.delete(spec, "additionalProperties"), method)
  end
  def build_object_deps(spec = %{"dependencies" => dobj}, method) do
    object_property_dep(dobj, method) ++
    build_object_deps(Map.delete(spec, "dependencies"), method)
  end
  def build_object_deps(_, _), do: []

  def build_array_deps(spec = %{"additionalItems" => props, "items" => parr}, method) when is_list(parr) do
    array_additional_dep(props, method) ++
    build_array_deps(Map.delete(spec, "additionalItems"), method)
  end
  def build_array_deps(spec = %{"items" => iobj}, method) do
    array_items_dep(iobj, method) ++
    build_array_deps(Map.delete(spec, "items"), method)
  end
  def build_array_deps(spec = %{"contains" => cobj}, method) do
    array_contains_dep(cobj, method) ++
    build_array_deps(Map.delete(spec, "contains"), method)
  end
  def build_array_deps(_,_), do: []

  def object_property_dep(dobj, method) do
    Enum.flat_map(dobj, &property_dep(&1, method))
  end

  def check_property_dependency(map, key, module, method) do
    Map.has_key?(map, key) &&
    (
      module
      |> apply(method, [map])
      |> case do
        :ok -> false
        any -> any
      end
    )
  end

  def property_dep({k, v}, method) when is_list(v) do
    dep_method = generate_submethod(method, k <> "_dependency")
    [quote do
      def unquote(dep_method)(val) do
        prop_list = unquote(v)
        if Enum.all?(prop_list, &Map.has_key?(val, &1)) do
          :ok
        else
          Exonerate.Macro.mismatch(__MODULE__, unquote(dep_method), val)
        end
      end
    end]
  end
  def property_dep({k, v}, method) when is_map(v) do
    dep_method = generate_submethod(method, k <> "_dependency")
    v
    |> Map.put("type", "object")
    |> matcher(dep_method)
  end
  def property_dep({k, v}, method) do
    dep_method = generate_submethod(method, k <> "_dependency")
    matcher(v, dep_method)
  end

  #TODO: rename this thing.
  @spec object_dep({String.t, Exonerate.schema}, atom) :: [defblock]
  def object_dep({k, v}, method) do
    new_method = generate_submethod(method, k)
    matcher(v, new_method)
  end

  def patt_prop(v, idx, method) do
    patt_method = generate_submethod(method, "pattern_#{idx}")
    matcher(v, patt_method)
  end

  def array_additional_dep(prop, method) do
    add_method = generate_submethod(method, "additional_items")
    matcher(prop, add_method)
  end

  def array_items_dep(iarr, method) when is_list(iarr) do
    iarr
    |> Enum.with_index
    |> Enum.flat_map(fn {spec, idx} ->
      item_method = generate_submethod(method, "item_#{idx}")
      matcher(spec, item_method)
    end)
  end
  def array_items_dep(iobj, method) do
    items_method = generate_submethod(method, "items")
    matcher(iobj, items_method)
  end

  def array_contains_dep(cobj, method) do
    contains_method = generate_submethod(method, "contains")
    matcher(cobj, contains_method)
  end

  @spec generate_submethod(atom, String.t) :: atom
  defp generate_submethod(method, sub) do
    method
    |> Atom.to_string
    |> Kernel.<>("__")
    |> Kernel.<>(sub)
    |> String.to_atom
  end

  def reduce_any(module, functions, base, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.any?(&(&1 == :ok))
    |> if do
      apply(module, base, args)
    else
      {:mismatch, {module, method, args}}
    end
  end

  def reduce_all(module, functions, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.all?(&(&1 == :ok))
    |> if do
      :ok
    else
      {:mismatch, {module, method, args}}
    end
  end

  def reduce_one(module, functions, args, method) do
    functions
    |> Enum.map(&apply(module, &1, args))
    |> Enum.count(&(&1 == :ok))
    |> case do
      1 -> :ok
      _ -> {:mismatch, {module, method, args}}
    end
  end

  def apply_not(module, method, args) do
    module
    |> apply(method, args)
    |> case do
      :ok -> {:mismatch, {module, method, args}}
      {:mismatch, _} -> :ok
    end
  end

  def check_pattern_properties(obj, regex, module, pp_method) do
    try do
      obj
      |> Map.keys
      |> Enum.filter(&Regex.match?(regex, &1))
      |> Enum.each(&check_pattern_property(obj[&1], module, pp_method))
      false
    catch
      any -> any
    end
  end

  def check_pattern_property(value, module, pp_method) do
    module
    |> apply(pp_method, [value])
    |> throw_if_invalid
  end

  def check_property_names(obj, module, pn_method) do
    try do
      Enum.each(obj, &check_property_name(&1, module, pn_method))
      false
    catch
      any -> any
    end
  end

  def check_property_name({k, _v}, module, pn_method) do
    module
    |> apply(pn_method, [k])
    |> throw_if_invalid
  end

  def check_additional_properties(obj, list, module, ap_method) do
    try do
      Enum.each(obj, &check_additional_property(&1, list, module, ap_method))
      false
    catch
      any -> any
    end
  end
  def check_additional_properties(obj, list, regexes, module, ap_method) do
    try do
      Enum.each(obj, &check_additional_property(&1, list, regexes, module, ap_method))
      false
    catch
      any -> any
    end
  end

  def check_additional_property({k, v}, list, module, ap_method) do
    if k in list do
      :ok
    else
      module
      |> apply(ap_method, [v])
      |> throw_if_invalid
    end
  end

  def check_additional_property({k, v}, list, regexes, module, ap_method) do
    cond do
      k in list -> :ok
      regexes
      |> Enum.map(&Regex.match?(&1, k))
      |> Enum.any? -> :ok
      true ->
        module
        |> apply(ap_method, [v])
        |> throw_if_invalid
    end
  end

  def check_additional_array(arr, tuple_count, module, ap_method) do
    try do
      arr
      |> Enum.with_index
      |> Enum.each(fn
        {_, idx} when idx < tuple_count -> :ok
        {val, _} ->
          module
          |> apply(ap_method, [val])
          |> throw_if_invalid
      end)
      false
    catch
      any -> any
    end
  end

  def check_property(nil, _, _), do: nil
  def check_property(obj, module, property_method) do
    module
    |> apply(property_method, [obj])
    |> case do
      :ok -> false
      any -> any
    end
  end

  def check_items(val, module, item_method) do
    try do
      Enum.each(val, &check_item(&1, module, item_method))
      false
    catch
      any -> any
    end
  end
  def check_item(val, module, item_method) do
    module
    |> apply(item_method, [val])
    |> throw_if_invalid
  end

  def check_tuple(val, idx, module, item_method) do
    check_val = Enum.at(val, idx)
    check_val && (
      module
      |> apply(item_method, [check_val])
      |> continue_if_ok
    )
  end

  def check_contains(val, module, cont_method) do
    if Enum.any?(val, &(apply(module, cont_method, [&1]) == :ok)) do
      :ok
    else
      Exonerate.Macro.mismatch(module, cont_method, val)
    end
  end

  def contains_duplicate?(array), do: contains_duplicate?(array, MapSet.new())
  def contains_duplicate?([], _), do: false
  def contains_duplicate?([head | tail], set) do
    if MapSet.member?(set, head) do
      true
    else
      contains_duplicate?(tail, MapSet.put(set, head))
    end
  end

  def throw_if_invalid(:ok), do: :ok
  def throw_if_invalid(any), do: throw any

  def continue_if_ok(:ok), do: false
  def continue_if_ok(any), do: any

end
