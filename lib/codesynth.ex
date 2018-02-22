defmodule Exonerate.Codesynth do
  def buildmodule_string(modulename, schemaname, schema) do
    """
      defmodule #{modulename} do

        require Exonerate.Checkers
        require Exonerate

        #{validator_string(schemaname, schema)}
      end
    """
    |> Code.format_string!()
    |> Enum.join()
  end

  ##############################################################################
  ## main subcomponent functions

  def validator_string(name, schema) do
    Enum.join(
      [
        dependencies_string(name, schema),
        validatorfn_string(name, schema),
        finalizer_string(name, schema)
      ],
      "\n"
    )
  end

  # the dependencies strings are components (regex + fun) that we need to do
  # some of the heavy lifting for things we can't simply use guards on, also for
  # things where we need direct recursion to evaluate subschemas.
  def dependencies_string(name, schema) do
    """
      #{regexstring(name, schema)}
      #{additionals_string(name, schema)}
      #{patternpropertystring(name, schema)}
      #{subschemastring(name, schema)}
      #{validate_qualifier_string(name, schema)}
      #{validateeachstring(name, schema)}
    """
  end

  # the validator function is the main workhorse which does much of the
  # processing of the string.  It mostly contains guards which filter the
  # processing, but also body components that are used for map/reduce type
  # assembly of validation results.

  # single special case values:
  def validatorfn_string(name, true), do: "def validate_#{name}(val), do: :ok"

  def validatorfn_string(name, false),
    do:
      "def validate_#{name}(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}"

  # nil requires a special handler.
  def validatorfn_string(name, %{"type" => "null"}) do
    """
      def validate_#{name}(nil), do: :ok
    """
    |> Code.format_string!()
    |> Enum.join()
  end

  # special case when we have minItems/maxItems in the array spec:

  def validatorfn_string(name, schema = %{"multipleOf" => v, "type" => "integer"}) do
    "def validate_#{name}(val) when is_integer(val) and (rem(val,#{v}) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "multipleOf"))
  end

  def validatorfn_string(name, schema = %{"multipleOf" => v, "type" => "number"}) do
    "def validate_#{name}(val) when is_integer(val) and (rem(val,#{v}) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "multipleOf"))
  end

  def validatorfn_string(name, schema = %{"multipleOf" => v, "type" => typelist})
      when is_list(typelist) do
    if "number" in typelist || "integer" in typelist do
      "def validate_#{name}(val) when is_integer(val) and (rem(val,#{v}) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
        validatorfn_string(name, Map.delete(schema, "multipleOf"))
    else
      validatorfn_string(name, Map.delete(schema, "multipleOf"))
    end
  end

  def validatorfn_string(name, schema = %{"multipleOf" => v}) do
    "def validate_#{name}(val) when is_integer(val) and (rem(val,#{v}) != 0), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "multipleOf"))
  end

  ##############################################################################

  def validatorfn_string(
        name,
        schema = %{"minimum" => v, "exclusiveMinimum" => true, "type" => "integer"}
      ) do
    "def validate_#{name}(val) when is_integer(val) and val <= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  def validatorfn_string(
        name,
        schema = %{"minimum" => v, "exclusiveMinimum" => true, "type" => "number"}
      ) do
    "def validate_#{name}(val) when is_number(val) and val <= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  def validatorfn_string(
        name,
        schema = %{"minimum" => v, "exclusiveMinimum" => true, "type" => typelist}
      )
      when is_list(typelist) do
    cond do
      "number" in typelist ->
        "def validate_#{name}(val) when is_number(val) and val <= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "minimum"))

      "integer" in typelist ->
        "def validate_#{name}(val) when is_integer(val) and val <= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "minimum"))

      true ->
        validatorfn_string(name, Map.delete(schema, "minimum"))
    end
  end

  def validatorfn_string(name, schema = %{"minimum" => v, "exclusiveMinimum" => true}) do
    "def validate_#{name}(val) when is_number(val) and val <= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  ##############################################################################

  def validatorfn_string(
        name,
        schema = %{"maximum" => v, "exclusiveMaximum" => true, "type" => "integer"}
      ) do
    "def validate_#{name}(val) when is_integer(val) and val >= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maximum"))
  end

  def validatorfn_string(
        name,
        schema = %{"maximum" => v, "exclusiveMaximum" => true, "type" => "number"}
      ) do
    "def validate_#{name}(val) when is_number(val) and val >= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maximum"))
  end

  def validatorfn_string(
        name,
        schema = %{"maximum" => v, "exclusiveMaximum" => true, "type" => typelist}
      )
      when is_list(typelist) do
    cond do
      "number" in typelist ->
        "def validate_#{name}(val) when is_number(val) and val >= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "maximum"))

      "integer" in typelist ->
        "def validate_#{name}(val) when is_integer(val) and val >= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "maximum"))

      true ->
        validatorfn_string(name, Map.delete(schema, "maximum"))
    end
  end

  def validatorfn_string(name, schema = %{"maximum" => v, "exclusiveMaximum" => true}) do
    "def validate_#{name}(val) when is_number(val) and val >= #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maximum"))
  end

  ##############################################################################

  def validatorfn_string(name, schema = %{"minimum" => v, "type" => "integer"}) do
    "def validate_#{name}(val) when is_integer(val) and val < #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  def validatorfn_string(name, schema = %{"minimum" => v, "type" => "number"}) do
    "def validate_#{name}(val) when is_number(val) and val < #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  def validatorfn_string(name, schema = %{"minimum" => v, "type" => typelist})
      when is_list(typelist) do
    cond do
      "number" in typelist ->
        "def validate_#{name}(val) when is_number(val) and val < #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "minimum"))

      "integer" in typelist ->
        "def validate_#{name}(val) when is_integer(val) and val < #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "minimum"))

      true ->
        validatorfn_string(name, Map.delete(schema, "minimum"))
    end
  end

  def validatorfn_string(name, schema = %{"minimum" => v}) do
    "def validate_#{name}(val) when is_number(val) and val < #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minimum"))
  end

  ##############################################################################

  def validatorfn_string(name, schema = %{"maximum" => v, "type" => "integer"}) do
    "def validate_#{name}(val) when is_integer(val) and val > #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maximum"))
  end

  def validatorfn_string(name, schema = %{"maximum" => v, "type" => "number"}) do
    "def validate_#{name}(val) when is_number(val) and val > #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maxno need to exchange info personally.

imum"))
  end

  def validatorfn_string(name, schema = %{"maximum" => v, "type" => typelist})
      when is_list(typelist) do
    cond do
      "number" in typelist ->
        "def validate_#{name}(val) when is_number(val) and val > #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "maximum"))

      "integer" in typelist ->
        "def validate_#{name}(val) when is_integer(val) and val > #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
          validatorfn_string(name, Map.delete(schema, "maximum"))

      true ->
        validatorfn_string(name, Map.delete(schema, "maximum"))
    end
  end

  def validatorfn_string(name, schema = %{"maximum" => v}) do
    "def validate_#{name}(val) when is_number(val) and val > #{v}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maximum"))
  end

  ##############################################################################

  def validatorfn_string(name, schema = %{"minItems" => l}) do
    "def validate_#{name}(val) when is_list(val) and length(val) < #{l}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "minItems"))
  end

  def validatorfn_string(name, schema = %{"maxItems" => l}) do
    "def validate_#{name}(val) when is_list(val) and length(val) > #{l}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "maxItems"))
  end

  def validatorfn_string(name, schema = %{"additionalItems" => false, "items" => array})
      when is_list(array) do
    l = length(array)

    "def validate_#{name}(val) when is_list(val) and length(val) > #{l}, do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}\n" <>
      validatorfn_string(name, Map.delete(schema, "additionalItems"))
  end

  # these three cases are when there's type information; they pass to the triplet definition.
  def validatorfn_string(name, schema = %{"type" => type}) when is_binary(type) do
    validatorfn_string(name, schema, type)
  end

  def validatorfn_string(name, schema = %{"type" => type}) when is_list(type) do
    Enum.map(type, &validatorfn_string(name, schema, &1)) |> Enum.join("\n")
  end

  # trampoline an untyped schema back to all schemas that need special declations
  # plus a catch-all.  Using the :qualifier atom allows it to be caught only by
  # the qualifier bodystring methods.
  def validatorfn_string(name, schema = %{}) do
    validatorfn_string(name, Map.put(schema, "type", find_type_dependencies(schema))) <>
      "\n def validate_#{name}(val), do: #{bodystring(name, schema, :qualifier)}"
  end

  ## the triplet type actually passes critical type information on to subcomponents
  def validatorfn_string(name, schema = %{"required" => _}, type = "object") do
    """
      def validate_#{name}(val #{requiredstring(schema, type)}) when is_map(val), do: #{bodystring(name, schema, type)}
      def validate_#{name}(val) when is_map(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """
  end

  def validatorfn_string(name, schema, type) do
    "def validate_#{name}(val) #{guardstring(schema, type)}, do: #{bodystring(name, schema, type)}"
  end

  # the finalizer decides whether or not we want to trap invalid schema elements.
  # if a "type" specification has been made, then we do, if not, then the schema
  # is permissive. A default value (even if it is not compliant will always)
  # self-validate.
  def finalizer_string(name, %{"default" => _}), do: "def validate_#{name}(val), do: :ok"

  def finalizer_string(name, %{"type" => _}),
    do:
      "def validate_#{name}(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}"

  def finalizer_string(name, _), do: ""

  ##############################################################################
  ## dependencies_string subcomponents
  ##

  # precompiled regexes can come from either string patterns or object key
  # patterns, which are called "patternProperties" in JSONSchema.

  def regexstring(name, spec), do: regexes(name, spec) |> Enum.join("\n")

  def regexes(name, spec = %{"pattern" => p}),
    do: [
      "@pattern_#{name} Regex.compile(\"#{p}\") |> elem(1)\n"
      | regexes(name, Map.delete(spec, "pattern"))
    ]

  def regexes(name, spec = %{"patternProperties" => p}) do
    (p
     |> Map.keys()
     |> Enum.with_index()
     |> Enum.map(fn {pp, idx} ->
          "@patternprop_#{name}_#{idx} Regex.compile(\"#{pp}\") |> elem(1)\n"
        end)) ++ regexes(name, Map.delete(spec, "patternProperties"))
  end

  def regexes(_name, _), do: []

  # additional properties are properties that have to be validated but do not
  # correspond to a particular defined property.  These will be generated as
  # functions with __additionals appended (this could cause a collision if
  # someone makes JSONSchema requiring a key value of _additionals for an object
  # on top of one demanding additionals.)
  def additionals_string(name, schema = %{"additionalProperties" => ap}) when is_map(ap) do
    [
      validator_string("#{name}__additionalProperties", ap),
      additionals_string(name, Map.delete(schema, "additionalProperties"))
    ]
    |> Enum.join("\n")
  end

  def additionals_string(name, schema = %{"additionalItems" => ai}) when is_map(ai) do
    [
      validator_string("#{name}__additionalItems", ai),
      additionals_string(name, Map.delete(schema, "additionalItems"))
    ]
    |> Enum.join("\n")
  end

  def additionals_string(_, _), do: ""

  # pattern properties are object properties that have to be validated but do not
  # have a definitive map name.  These will be validated by sequential functions
  # that are mapped to unique numbers.
  def patternpropertystring(name, %{"patternProperties" => map}) when is_map(map) do
    map
    |> Enum.with_index()
    |> Enum.map(fn {{k, v}, idx} ->
         validator_string("#{name}__pattern_#{idx}", v)
       end)
    |> Enum.join("\n\n")
  end

  def patternpropertystring(_, _), do: ""

  # subschemas are recursive validations that come from either arrays or
  # object properties, or qualifiers.
  def subschemastring(name, schema = %{"allOf" => list}) when is_list(list) do
    (list
     |> Enum.with_index()
     |> Enum.map(fn {v, idx} ->
          validator_string("#{name}__allof_#{idx}", v)
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "allOf"))
  end

  def subschemastring(name, schema = %{"anyOf" => list}) when is_list(list) do
    (list
     |> Enum.with_index()
     |> Enum.map(fn {v, idx} ->
          validator_string("#{name}__anyof_#{idx}", v)
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "anyOf"))
  end

  def subschemastring(name, schema = %{"oneOf" => list}) when is_list(list) do
    (list
     |> Enum.with_index()
     |> Enum.map(fn {v, idx} ->
          validator_string("#{name}__oneof_#{idx}", v)
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "oneOf"))
  end

  def subschemastring(name, schema = %{"not" => subschema}) when is_map(subschema) do
    validator_string("#{name}__not", subschema) <>
      subschemastring(name, Map.delete(schema, "not"))
  end

  def subschemastring(name, schema = %{"dependencies" => deps_map}) when is_map(deps_map) do
    (deps_map
     |> Enum.map(fn {k, v} ->
          if is_map(v) do
            validator_string("#{name}__deps_#{k}", v)
          else
            deps_array("#{name}__deps_#{k}", k, v)
          end
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "dependencies"))
  end

  def subschemastring(name, schema = %{"items" => list}) when is_list(list) do
    (list
     |> Enum.with_index()
     |> Enum.map(fn {v, idx} ->
          validator_string("#{name}_#{idx}", v)
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "items"))
  end

  def subschemastring(name, schema = %{"properties" => map}) when is_map(map) do
    (map
     |> Enum.map(fn {k, v} ->
          validator_string("#{name}_#{k}", v)
        end)
     |> Enum.join("\n\n")) <> subschemastring(name, Map.delete(schema, "properties"))
  end

  def subschemastring(_, _), do: ""

  def validate_qualifier_string(name, schema = %{"allOf" => list}) do
    validation_list =
      list
      |> Enum.with_index()
      |> Enum.map(fn {_v, idx} -> "validate_#{name}__allof_#{idx}(val)" end)
      |> Enum.join(",")

    """
      def validate_#{name}__allof(val), do: [#{validation_list}] |> Exonerate.error_reduction

    """ <> validate_qualifier_string(name, Map.delete(schema, "allOf"))
  end

  def validate_qualifier_string(name, schema = %{"anyOf" => list}) do
    validation_list =
      list
      |> Enum.with_index()
      |> Enum.map(fn {_v, idx} -> "(validate_#{name}__anyof_#{idx}(val) == :ok) -> :ok" end)
      |> Enum.join("\n")

    """
      def validate_#{name}__anyof(val) do
        cond do
          #{validation_list}
          true -> {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
        end
      end

    """ <> validate_qualifier_string(name, Map.delete(schema, "anyOf"))
  end

  def validate_qualifier_string(name, schema = %{"oneOf" => list}) do
    validation_list =
      list
      |> Enum.with_index()
      |> Enum.map(fn {_v, idx} -> "&__MODULE__.validate_#{name}__oneof_#{idx}/1" end)
      |> Enum.join(",")

    """
      def validate_#{name}__oneof(val) do
        count = [#{validation_list}]
          |> Enum.map(fn f -> f.(val) end)
          |> Enum.count(fn res -> res == :ok end)
        if count == 1, do: :ok, else: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      end

    """ <> validate_qualifier_string(name, Map.delete(schema, "oneOf"))
  end

  def validate_qualifier_string(name, schema = %{"enum" => list}) do
    validation_list =
      list
      |> Enum.map(fn v -> ~s(#{inspect(v)}) end)
      |> Enum.join(",")

    """
      def validate_#{name}__enum(val) do
        if val in [#{validation_list}], do: :ok, else: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      end

    """ <> validate_qualifier_string(name, Map.delete(schema, "enum"))
  end

  def validate_qualifier_string(name, schema = %{"dependencies" => depsmap}) do
    deps_fnmap =
      depsmap
      |> Enum.map(fn {k, _v} -> "\"#{k}\" => &__MODULE__.validate_#{name}__deps_#{k}/1" end)
      |> Enum.join(",")
      |> (fn s -> ~s(%{#{s}}) end).()

    """
      def validate_#{name}__deps(val) do
        depsmap = #{deps_fnmap}
        Map.keys(val)
          |> Enum.filter(&Map.has_key?(depsmap, &1))
          |> Enum.map(fn k -> depsmap[k].(val) end)
          |> Exonerate.error_reduction
      end
    """
  end

  def validate_qualifier_string(name, _), do: ""

  @doc """
    a helper function to handle deps arrays
  """
  def deps_array(name, keyname, deps_list) do
    key_list =
      deps_list
      |> Enum.map(fn s -> ~s("#{s}") end)
      |> Enum.join(",")

    """
      def validate_#{name}(val) do
        required_key_list = [#{key_list}]
        actual_key_list = Map.keys(val)

        is_valid = required_key_list |> Enum.all?(fn k -> k in actual_key_list end)
        if is_valid, do: :ok, else: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
      end
    """
  end

  # validate_each functions are functions that remap onto the subschema functions
  # intended to be called as a result of a Enum.map in the main validator function
  # note that maps map over {k, v} and lists map over {v}.

  def simpleobject(%{"additionalProperties" => _}), do: false
  def simpleobject(%{"patternProperties" => _}), do: false
  def simpleobject(%{"properties" => p}), do: p |> Map.keys() |> length <= 1
  def simpleobject(_), do: true

  def validateeachstring(
        name,
        map = %{"type" => "array", "items" => list, "additionalItems" => schema}
      )
      when is_list(list) and is_map(schema) do
    itemvalidationarray =
      0..(length(list) - 1) |> Enum.map(fn i -> "&__MODULE__.validate_#{name}_#{i}/1" end)
      |> Enum.join(",")

    """
      def validate_#{name}__all(val) do
        Exonerate.Checkers.check_additionalitems(val, [#{itemvalidationarray}], &__MODULE__.validate_#{
      name
    }__additionalItems/1)
      end
    """
  end

  def validateeachstring(name, map = %{"type" => "array", "items" => list})
      when is_list(list) and length(list) > 0 do
    itemvalidationarray =
      0..(length(list) - 1) |> Enum.map(fn i -> "&__MODULE__.validate_#{name}_#{i}/1" end)
      |> Enum.join(",")

    """
      def validate_#{name}__all(val) do
        val |> Enum.zip([#{itemvalidationarray}])
            |> Enum.map(fn {a, f} -> f.(a) end)
            |> Exonerate.error_reduction
      end
    """
  end

  def validateeachstring(name, map = %{"type" => "array", "items" => schema}) when is_map(schema),
    do: validator_string("#{name}__forall", schema)

  def validateeachstring(name, map = %{"type" => "object"}) do
    if simpleobject(map) do
      ""
    else
      """
        def validate_#{name}__each({k,v}) do
          #{patternmatch_string(name, map)}
          #{querymatch_string(name, map)}
          #{combining_string(name, map)}
        end
      """
    end
  end

  def validateeachstring(name, schema = %{"type" => typearr}) when is_list(typearr) do
    maybe_object =
      if "object" in typearr,
        do: validateeachstring(name, Map.put(schema, "type", "object")),
        else: ""

    maybe_array =
      if "array" in typearr,
        do: validateeachstring(name, Map.put(schema, "type", "array")),
        else: ""

    Enum.join([maybe_object, maybe_array], "\n")
  end

  def validateeachstring(name, %{"type" => _}), do: ""
  def validateeachstring(name, bool) when is_boolean(bool), do: ""
  # for untyped schemas we have to decide if we need these validation guards, we
  # do this by redispatching over our find_type_dependencies utility.
  def validateeachstring(name, schema) do
    validateeachstring(name, Map.put(schema, "type", find_type_dependencies(schema)))
  end

  def patternmatch_string(name, schema = %{"patternProperties" => map}) do
    {validation, shortfn, default} =
      case schema["additionalProperties"] do
        false -> {"{validate_#{name}__pattern_0(v), true}", "{f.(v), true}", "{:ok, false}"}
        nil -> {"validate_#{name}__pattern_0(v)", "f.(v)", ":ok"}
        _ -> {"{validate_#{name}__pattern_0(v), true}", "{f.(v), true}", "{:ok, false}"}
      end

    l = Map.keys(map) |> length

    case l do
      0 ->
        ""

      1 ->
        "pmatch = if Regex.match?(@patternprop_#{name}_0, k), do: #{validation}, else: #{default}"

      _ ->
        patt_lst =
          0..(l - 1) |> Enum.map(fn idx -> "@patternprop_#{name}_#{idx}" end) |> Enum.join(",")

        test_lst =
          0..(l - 1) |> Enum.map(fn idx -> "&__MODULE__.validate_#{name}__pattern_#{idx}/1" end)
          |> Enum.join(",")

        """
        pmatch = Enum.zip([#{patt_lst}], [#{test_lst}])
          |> Enum.map(fn {r, f} -> if Regex.match?(r,k), do: #{shortfn}, else: #{default} end)
        """
    end
  end

  def patternmatch_string(_name, _), do: ""

  def querymatch_string(name, schema = %{"properties" => properties}) do
    {validation, default} =
      case schema["additionalProperties"] do
        false -> {fn ky -> "\"#{ky}\" -> {validate_#{name}_#{ky}(v), true}" end, "{:ok, false}"}
        nil -> {fn ky -> "\"#{ky}\" ->  validate_#{name}_#{ky}(v)" end, ":ok"}
        _ -> {fn ky -> "\"#{ky}\" -> {validate_#{name}_#{ky}(v), true}" end, "{:ok, false}"}
      end

    query_match_strings =
      properties
      |> Map.keys()
      |> Enum.map(validation)
      |> Enum.join("\n")

    """
      qmatch = case k do
        #{query_match_strings}
        _ -> #{default}
      end
    """
  end

  def querymatch_string(_, _), do: ""

  def default_check(_name, %{"additionalProperties" => false}),
    do: "{:error, \"does not conform to JSON schema\"}"

  def default_check(name, %{"additionalProperties" => _}),
    do: "validate_#{name}__additionalProperties(v)"

  def combining_string(
        name,
        schema = %{"patternProperties" => pprop, "properties" => _, "additionalProperties" => _}
      ) do
    connector = if pprop |> Map.keys() |> length == 1, do: ",", else: "|"

    """
      {result, matched} = [qmatch #{connector} pmatch] |> Enum.unzip
      if Enum.any?(matched), do: result |> Exonerate.error_reduction(), else: #{
      default_check(name, schema)
    }
    """
  end

  def combining_string(
        name,
        schema = %{"patternProperties" => pprop, "additionalProperties" => _}
      ) do
    if pprop |> Map.keys() |> length == 1 do
      """
        {result, matched} = pmatch
        if matched, do: result, else: #{default_check(name, schema)}
      """
    else
      """
        {result, matched} = Enum.unzip(pmatch)
        if Enum.any?(matched), do: result |> Exonerate.error_reduction(), else: #{
        default_check(name, schema)
      }
      """
    end
  end

  def combining_string(name, schema = %{"properties" => _, "additionalProperties" => _}) do
    """
      {result, matched} = qmatch
      if matched, do: result, else: #{default_check(name, schema)}
    """
  end

  def combining_string(name, %{"additionalProperties" => _}) do
    """
      validate_#{name}__additionalProperties(v)
    """
  end

  # without additional properties
  def combining_string(name, %{"patternProperties" => pprop, "properties" => _}) do
    if pprop |> Map.keys() |> length == 1,
      do: "[qmatch , pmatch] |> Exonerate.error_reduction",
      else: "[qmatch | pmatch] |> Exonerate.error_reduction"
  end

  def combining_string(name, %{"patternProperties" => pprop}) do
    if pprop |> Map.keys() |> length == 1, do: "", else: "|> Exonerate.error_reduction"
  end

  def combining_string(name, %{"properties" => _}), do: ""
  def combining_string(_, _), do: ""

  ##############################################################################
  ## validator function subcomponents
  ##

  def mappingfn(name, %{"patternProperties" => _}, "object"),
    do: "Enum.map(val, &__MODULE__.validate_#{name}__each/1)"

  def mappingfn(name, %{"additionalProperties" => _}, "object"),
    do: "Enum.map(val, &__MODULE__.validate_#{name}__each/1)"

  def mappingfn(name, %{"properties" => prop}, "object") do
    if length(Map.keys(prop)) > 1,
      do: "Enum.map(val, &__MODULE__.validate_#{name}__each/1)",
      else: nil
  end

  def mappingfn(name, %{"items" => schema}, "array") when is_map(schema),
    do: "Enum.map(val, &__MODULE__.validate_#{name}__forall/1)"

  def mappingfn(_, _, _), do: nil

  # assemble a guard string.
  def guardstring(spec, type), do: guards(spec, type) |> guardproc(type)
  def guardproc([], type), do: "when #{guardverb(type)}"
  def guardproc(arr, type), do: "when #{guardverb(type)} and " <> Enum.join(arr, " and ")

  def guardverb("string"), do: "is_binary(val)"
  def guardverb("integer"), do: "is_integer(val)"
  def guardverb("number"), do: "is_number(val)"
  def guardverb("boolean"), do: "is_boolean(val)"
  def guardverb("none"), do: "is_nil(val)"
  def guardverb("array"), do: "is_list(val)"
  def guardverb("object"), do: "is_map(val)"

  def guards(_, _), do: []

  @fmt_map %{
    "date-time" => "datetime",
    "email" => "email",
    "hostname" => "hostname",
    "ipv4" => "ipv4",
    "ipv6" => "ipv6",
    "uri" => "uri"
  }

  def bodystring(name, schema, type),
    do: bodyproc(name, bodyfns(name, schema, type), mappingfn(name, schema, type))

  def bodyproc(name, [], nil), do: ":ok"
  def bodyproc(name, [], mapfn), do: "#{mapfn} |> Exonerate.error_reduction"
  def bodyproc(name, [singleton], nil), do: singleton

  def bodyproc(name, [singleton], mapfn),
    do: "[#{singleton} | #{mapfn}] |> Exonerate.error_reduction"

  def bodyproc(name, arr, nil), do: "[" <> Enum.join(arr, ",") <> "] |> Exonerate.error_reduction"

  def bodyproc(name, arr, mapfn),
    do: "([" <> Enum.join(arr, ",") <> "] ++ #{mapfn}) |> Exonerate.error_reduction"

  # some things can't be in guards, so we put them in bodies:
  def bodyfns(name, schema = %{"pattern" => _p}, "string"),
    do: [
      "Exonerate.Checkers.check_regex(@pattern_#{name}, val)"
      | bodyfns(name, Map.delete(schema, "pattern"), "string")
    ]

  def bodyfns(name, schema = %{"format" => p}, "string"),
    do: [
      "Exonerate.Checkers.check_format_#{@fmt_map[p]}(val)"
      | bodyfns(name, Map.delete(schema, "format"), "string")
    ]

  def bodyfns(name, schema = %{"minLength" => l}, "string"),
    do: [
      "Exonerate.Checkers.check_minlength(val, #{l})"
      | bodyfns(name, Map.delete(schema, "minLength"), "string")
    ]

  def bodyfns(name, schema = %{"maxLength" => l}, "string"),
    do: [
      "Exonerate.Checkers.check_maxlength(val, #{l})"
      | bodyfns(name, Map.delete(schema, "maxLength"), "string")
    ]

  def bodyfns(name, schema = %{"minProperties" => p}, "object"),
    do: [
      "Exonerate.Checkers.check_minproperties(val, #{p})"
      | bodyfns(name, Map.delete(schema, "minProperties"), "object")
    ]

  def bodyfns(name, schema = %{"maxProperties" => p}, "object"),
    do: [
      "Exonerate.Checkers.check_maxproperties(val, #{p})"
      | bodyfns(name, Map.delete(schema, "maxProperties"), "object")
    ]

  def bodyfns(name, schema = %{"dependencies" => d}, "object"),
    do: [
      "validate_#{name}__deps(val)" | bodyfns(name, Map.delete(schema, "dependencies"), "object")
    ]

  def bodyfns(name, schema = %{"properties" => p}, "object") do
    if p |> Map.keys() |> length == 1 && simpleobject(schema) do
      (p |> Enum.map(fn {k, v} -> "(if Map.has_key?(val, \"#{k}\"), do: validate_#{name}_#{k}(val[\"#{k}\"]), else: :ok)" end)) ++
        bodyfns(name, Map.delete(schema, "properties"), "object")
    else
      bodyfns(name, Map.delete(schema, "properties"), "object")
    end
  end

  def bodyfns(name, schema = %{"uniqueItems" => true}, "array"),
    do: [
      "Exonerate.Checkers.check_unique(val)"
      | bodyfns(name, Map.delete(schema, "uniqueItems"), "array")
    ]

  def bodyfns(name, schema = %{"items" => list}, "array") when is_list(list) and length(list) > 0,
    do: ["validate_#{name}__all(val)" | bodyfns(schema, Map.delete(schema, "items"), "array")]

  def bodyfns(name, schema = %{"allOf" => list}, type),
    do: ["validate_#{name}__allof(val)" | bodyfns(name, Map.delete(schema, "allOf"), type)]

  def bodyfns(name, schema = %{"anyOf" => list}, type),
    do: ["validate_#{name}__anyof(val)" | bodyfns(name, Map.delete(schema, "anyOf"), type)]

  def bodyfns(name, schema = %{"oneOf" => list}, type),
    do: ["validate_#{name}__oneof(val)" | bodyfns(name, Map.delete(schema, "oneOf"), type)]

  def bodyfns(name, schema = %{"enum" => list}, type),
    do: ["validate_#{name}__enum(val)" | bodyfns(name, Map.delete(schema, "enum"), type)]

  def bodyfns(name, schema = %{"not" => list}, type),
    do: [
      "Exonerate.invert(val, validate_#{name}__not(val))"
      | bodyfns(name, Map.delete(schema, "not"), type)
    ]

  def bodyfns(_name, _, _), do: []

  # one last special sugar for objects
  def requiredstring(%{"required" => list}, "object"),
    do:
      Enum.map(list, fn s -> ~s("#{s}" => _) end) |> Enum.join(",") |> (fn s -> "=%{#{s}}" end).()

  def requiredstring(_, _), do: ""

  @sourcetype %{
    "minLength" => "string",
    "maxLength" => "string",
    "format" => "string",
    "pattern" => "string",
    "multipleOf" => "number",
    "minimum" => "number",
    "maximum" => "number",
    "properties" => "object",
    "additionalProperties" => "object",
    "required" => "object",
    "minProperties" => "object",
    "maxProperties" => "object",
    "dependencies" => "object",
    "patternProperties" => "object",
    "items" => "array",
    "uniqueItems" => "array",
    "additionalItems" => "array",
    "minItems" => "array",
    "maxItems" => "array"
  }

  # goes through a list of properties and searches for dependencies
  def find_type_dependencies(schema) do
    schema
    |> Enum.map(fn {k, _v} -> @sourcetype[k] end)
    |> Enum.filter(& &1)
    |> Enum.uniq()
  end
end
