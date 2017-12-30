defmodule Exonerate.Validation.Helper do
  @moduledoc """
    this module provides the parameter and numeric_parameter macros which
    enable the validation scripts to be a DSL around the validation_kv function
    which does the fallthrough analysis of parameters modifying JSONschemata
    types.
  """

  @doc """
    maps between symbols and a corresponding check phrase to ensure that
    parameter values are typechecked.
  """
  def checkfn(:integer),
    do:
      (quote do
         is_integer(val)
       end)

  def checkfn(:format),
    do:
      (quote do
         val in ["date-time", "email", "hostname", "ipv4", "ipv6", "uri"]
       end)

  def checkfn(:string),
    do:
      (quote do
         is_binary(val)
       end)

  def checkfn(:number),
    do:
      (quote do
         is_number(val)
       end)

  def checkfn(:map),
    do:
      (quote do
         is_map(val)
       end)

  def checkfn(:addprop),
    do:
      (quote do
         is_map(val) or is_boolean(val)
       end)

  def checkfn(:list),
    do:
      (quote do
         is_list(val)
       end)

  def checkfn(:items),
    do:
      (quote do
         is_map(val) or is_list(val)
       end)

  def checkfn(:boolean),
    do:
      (quote do
         is_boolean(val)
       end)

  def checkfn(:additem),
    do:
      (quote do
         is_map(val) or is_boolean(val)
       end)

  defmacro parameter(name, type, fortype, fallthrough \\ false) do
    checker = checkfn(type)
    errmsg = "non-#{fortype} typed object can't have #{name} parameter"
    valmsg = "#{name} can't be non-#{type} value"

    fallthru =
      if fallthrough do
        fallthrufn = String.to_atom("validate_" <> name)

        quote do
          unquote(fallthrufn)(map, val)
        end
      else
        :ok
      end

    quote do
      def validate_kv({unquote(name), val}, map = %{"type" => unquote(fortype)}, _)
          when unquote(checker),
          do: unquote(fallthru)

      def validate_kv({unquote(name), val}, map = %{"type" => type}, _)
          when unquote(checker) and is_binary(type),
          do: {:error, unquote(errmsg)}

      def validate_kv({unquote(name), val}, map = %{"type" => typelist}, _)
          when unquote(checker) and is_list(typelist),
          do:
            if(
              unquote(fortype) in typelist,
              do: unquote(fallthru),
              else: {:error, unquote(errmsg)}
            )

      def validate_kv({unquote(name), val}, map, _) when unquote(checker), do: unquote(fallthru)
      def validate_kv({unquote(name), val}, _, _), do: {:error, unquote(valmsg)}
    end
  end

  defmacro numeric_parameter(name, type) do
    checker = checkfn(type)
    errmsg = "non-numeric typed object can't have #{name} parameter"
    valmsg = "#{name} can't be non-#{type} value"

    quote do
      def validate_kv({unquote(name), val}, %{"type" => "integer"}, _) when unquote(checker),
        do: :ok

      def validate_kv({unquote(name), val}, %{"type" => "number"}, _) when unquote(checker),
        do: :ok

      def validate_kv({unquote(name), val}, %{"type" => type}, _)
          when unquote(checker) and is_binary(type),
          do: {:error, unquote(errmsg)}

      def validate_kv({unquote(name), val}, %{"type" => typelist}, _)
          when unquote(checker) and is_list(typelist),
          do:
            if(
              "integer" in typelist || "number" in typelist,
              do: :ok,
              else: {:error, unquote(errmsg)}
            )

      def validate_kv({unquote(name), val}, _, _) when unquote(checker), do: :ok
      def validate_kv({unquote(name), val}, _, _), do: {:error, unquote(valmsg)}
    end
  end
end

defmodule Exonerate.Validation do
  require Logger
  import Exonerate
  import Exonerate.Validation.Helper

  def isvalid(val), do: validate(val) == :ok

  def validate(value), do: validate(value, true)
  def validate(bool, _) when is_boolean(bool), do: :ok
  # we can validate references in another step.
  def validate(%{"$ref" => _}, false), do: :ok

  def validate(map, first) when is_map(map) do
    map |> Enum.map(&Exonerate.Validation.validate_kv(&1, map, first))
    |> error_reduction
  end

  def validate(_, _), do: {:error, "invalid type for validation"}

  ##############################################################################
  ## since JSON Schema is a recursive definition, the validate_kv function does
  ## most of the heavy lifting.

  @valid_types ["string", "integer", "number", "boolean", "null", "object", "array"]

  # type handling
  def validate_kv({"type", type}, _map, _) when is_binary(type) and type in @valid_types, do: :ok

  def validate_kv({"type", arr}, _map, _) when is_list(arr) do
    if Enum.map(arr, fn t -> t in @valid_types end) |> Enum.reduce(true, &Kernel.&&/2) do
      :ok
    else
      {:error, "type array contains unrecognized type"}
    end
  end

  # schema annotation handles
  def validate_kv({"$schema", _}, _map, true), do: :ok
  def validate_kv({"$schema", _}, _map, false), do: {:error, "$schema key not at root"}
  def validate_kv({"id", _}, _map, true), do: :ok
  def validate_kv({"id", _}, _map, false), do: {:error, "id key not at root"}

  def validate_kv({"definitions", map}, _map, true) when is_map(map),
    do: Enum.map(map, fn {_k, v} -> validate(v, false) end)

  # metadata keywords
  def validate_kv({"title", _}, _map, _), do: :ok
  def validate_kv({"description", _}, _map, _), do: :ok

  def validate_kv({"default", _}, _map, _) do
    Logger.warn("currently default values are not validated aganist the schema type")
    :ok
  end

  def validate_kv({"$ref", str}, _map_, _) when is_binary(str) do
    Logger.warn("currently references are not traversed and are not guaranteed to be valid")
    :ok
  end

  # compound schemas
  def validate_kv({"allOf", arr}, _map, _) when is_list(arr),
    do: Enum.map(arr, &validate(&1, false)) |> error_reduction

  def validate_kv({"anyOf", arr}, _map, _) when is_list(arr),
    do: Enum.map(arr, &validate(&1, false)) |> error_reduction

  def validate_kv({"oneOf", arr}, _map, _) when is_list(arr),
    do: Enum.map(arr, &validate(&1, false)) |> error_reduction

  def validate_kv({"not", map}, _map, _) when is_map(map), do: validate(map, false)

  # keyvalue pairs which have a type dependency requirement
  # strings
  #                   parameter name          parameter type      parameter modifies    fallthrough?
  parameter("minLength", :integer, "string")
  parameter("maxLength", :integer, "string")
  parameter("format", :format, "string")
  parameter("pattern", :string, "string")
  numeric_parameter("multipleOf", :number)
  numeric_parameter("minimum", :number)
  numeric_parameter("maximum", :number)
  parameter("properties", :map, "object", true)
  parameter("additionalProperties", :addprop, "object", true)
  parameter("required", :list, "object", true)
  parameter("minProperties", :integer, "object")
  parameter("maxProperties", :integer, "object")
  parameter("dependencies", :map, "object", true)
  parameter("patternProperties", :map, "object", true)
  parameter("items", :items, "array", true)
  parameter("uniqueItems", :boolean, "array")
  parameter("additionalItems", :additem, "array", true)
  parameter("minItems", :integer, "array")
  parameter("maxItems", :integer, "array")

  # a couple of strange ones that don't fit into the dominant rubric:
  def validate_kv({"exclusiveMinimum", bool}, %{"minimum" => _}, _) when is_boolean(bool), do: :ok
  def validate_kv({"exclusiveMaximum", bool}, %{"maximum" => _}, _) when is_boolean(bool), do: :ok

  # other keywords
  def validate_kv({"enum", enum_val}, _map, _)
      when is_list(enum_val)
      when length(enum_val) > 0 do
    Logger.warn("currently enum values are not validated aganist the schema type")
    :ok
  end

  def validate_kv({"enum", enum_val}, _map, _), do: {:error, "invalid enum #{enum_val}"}
  def validate_kv({k, _v}, _map, _), do: {:error, "unrecognized key #{inspect(k)}"}

  ##############################################################################
  ## specific, fallthrough validations:

  # fallthrough function on validate_properties
  def validate_properties(_parent, properties),
    do: Enum.map(properties, fn {_k, v} -> validate(v, false) end) |> error_reduction

  # fallthrough function on additional_properties:  can either be boolean or a valid schema
  def validate_additionalProperties(%{"properties" => _}, ap) when is_boolean(ap), do: :ok
  def validate_additionalProperties(%{"properties" => _}, ap), do: validate(ap, false)

  def validate_additionalProperties(parent, _) do
    Logger.warn("additionalProperties wants a properties object, missing in #{inspect(parent)}")
    :ok
  end

  # fallthrough function for required properties checks that everything in the required list appears in the properties map.
  def validate_required(parent = %{"properties" => props}, req) do
    Enum.map(req, fn key ->
      if key in Map.keys(props),
        do: :ok,
        else: {:error, "required item #{key} not in properties of #{inspect(parent)}"}
    end)
    |> error_reduction
  end

  def validate_required(parent, _),
    do: {:error, "required properties requires properties, missing in #{inspect(parent)}"}

  # fallthrough function for dependencies is a bit more complicated since it can either be an array of strings or a map of schemata
  def validate_dependencies(_parent, depmap),
    do: Enum.map(depmap, fn {_k, v} -> check_dependency(v) end) |> error_reduction

  # array of strings case:
  def check_dependency(deplist) when is_list(deplist) do
    if Enum.all?(deplist, &is_binary/1),
      do: :ok,
      else: {:error, "non-string item in dependency list: #{inspect(deplist)}"}
  end

  # or recursively check that it's a schema.
  def check_dependency(depmap) when is_map(depmap), do: validate(depmap, false)

  def check_dependency(value),
    do: {:error, "unrecognized value in dependency list #{inspect(value)}"}

  def validate_patternProperties(parent, pp),
    do: Enum.map(pp, fn {_k, v} -> validate(v, false) end) |> error_reduction

  def validate_items(_parent, obj) when is_map(obj), do: validate(obj, false)

  def validate_items(_parent, arr) when is_list(arr),
    do: Enum.map(arr, &validate(&1, false)) |> error_reduction

  def validate_additionalItems(%{"items" => list}, val) when is_list(list) and is_boolean(val),
    do: :ok

  def validate_additionalItems(%{"items" => list}, val) when is_list(list) and is_map(val),
    do: validate(val, false)

  def validate_additionalItems(parent, _val) do
    Logger.warn("aditionalitems wants a bounded item schema array, missing in #{inspect(parent)}")
    :ok
  end
end
