defmodule Exonerate.Modules do
  @moduledoc """
  Centralized module registry for Exonerate.

  Consolidates all module lookups (types, combining filters, object filters,
  array filters, format validators) into a single module for easier maintenance
  and discoverability.
  """

  # ============================================================================
  # Type Modules
  # ============================================================================

  @type_modules %{
    "string" => Exonerate.Type.String,
    "integer" => Exonerate.Type.Integer,
    "number" => Exonerate.Type.Number,
    "object" => Exonerate.Type.Object,
    "array" => Exonerate.Type.Array,
    "boolean" => Exonerate.Type.Boolean,
    "null" => Exonerate.Type.Null
  }

  @type_names Map.keys(@type_modules)

  @doc """
  Returns the module for a JSON type.

  ## Examples

      iex> Exonerate.Modules.type("string")
      Exonerate.Type.String

      iex> Exonerate.Modules.type("object")
      Exonerate.Type.Object
  """
  @spec type(String.t()) :: module() | nil
  def type(type_name), do: @type_modules[type_name]

  @doc "Returns all type names."
  @spec all_types() :: [String.t()]
  def all_types, do: @type_names

  # ============================================================================
  # Combining Modules
  # ============================================================================

  # Standard combining filters that apply to ALL types
  @standard_combining_modules %{
    "anyOf" => Exonerate.Combining.AnyOf,
    "allOf" => Exonerate.Combining.AllOf,
    "oneOf" => Exonerate.Combining.OneOf,
    "not" => Exonerate.Combining.Not,
    "$ref" => Exonerate.Combining.Ref,
    "if" => Exonerate.Combining.If
  }

  # Object-specific combining filter (dependentSchemas)
  @object_combining_module %{
    "dependentSchemas" => Exonerate.Combining.DependentSchemas
  }

  # All combining modules
  @all_combining_modules Map.merge(@standard_combining_modules, @object_combining_module)

  @combining_filters Map.keys(@standard_combining_modules)

  @doc """
  Returns the module for a combining filter.

  ## Examples

      iex> Exonerate.Modules.combining("allOf")
      Exonerate.Combining.AllOf

      iex> Exonerate.Modules.combining("$ref")
      Exonerate.Combining.Ref

      iex> Exonerate.Modules.combining("dependentSchemas")
      Exonerate.Combining.DependentSchemas
  """
  @spec combining(String.t()) :: module() | nil
  def combining(filter_name), do: @all_combining_modules[filter_name]

  @doc """
  Returns the standard combining filter names (excludes dependentSchemas).

  These are the combining filters that apply to all types, not just objects.
  """
  @spec combining_filters() :: [String.t()]
  def combining_filters, do: @combining_filters

  @doc """
  Returns true if the given filter name is a standard combining filter.

  Note: Returns false for "dependentSchemas" since it's object-specific.
  For a check that includes all combining-style filters, use `combining/1 != nil`.
  """
  @spec combining?(String.t()) :: boolean()
  def combining?(filter), do: is_map_key(@standard_combining_modules, filter)

  # ============================================================================
  # Object Filter Modules
  # ============================================================================

  @object_outer_modules %{
    "minProperties" => Exonerate.Filter.MinProperties,
    "maxProperties" => Exonerate.Filter.MaxProperties,
    "required" => Exonerate.Filter.Required,
    "dependencies" => Exonerate.Filter.Dependencies,
    "dependentRequired" => Exonerate.Filter.DependentRequired,
    "dependentSchemas" => Exonerate.Combining.DependentSchemas
  }

  @object_iterator_modules %{
    "properties" => Exonerate.Filter.Properties,
    "propertyNames" => Exonerate.Filter.PropertyNames,
    "patternProperties" => Exonerate.Filter.PatternProperties
  }

  @object_finalizer_modules %{
    "additionalProperties" => Exonerate.Filter.AdditionalProperties,
    "unevaluatedProperties" => Exonerate.Filter.UnevaluatedProperties
  }

  @object_all_modules Map.merge(@object_outer_modules, @object_iterator_modules)
                      |> Map.merge(@object_finalizer_modules)

  @doc """
  Returns the module for an object filter.

  ## Examples

      iex> Exonerate.Modules.object_filter("properties")
      Exonerate.Filter.Properties

      iex> Exonerate.Modules.object_filter("required")
      Exonerate.Filter.Required
  """
  @spec object_filter(String.t()) :: module() | nil
  def object_filter(filter_name), do: @object_all_modules[filter_name]

  @doc "Returns the outer object filter modules (non-iterator)."
  def object_outer_modules, do: @object_outer_modules

  @doc "Returns the iterator object filter modules."
  def object_iterator_modules, do: @object_iterator_modules

  @doc "Returns the finalizer object filter modules."
  def object_finalizer_modules, do: @object_finalizer_modules

  # ============================================================================
  # Array Filter Modules
  # ============================================================================

  @array_modules %{
    "items" => Exonerate.Filter.Items,
    "contains" => Exonerate.Filter.Contains,
    "uniqueItems" => Exonerate.Filter.UniqueItems,
    "minItems" => Exonerate.Filter.MinItems,
    "maxItems" => Exonerate.Filter.MaxItems,
    "additionalItems" => Exonerate.Filter.AdditionalItems,
    "prefixItems" => Exonerate.Filter.PrefixItems,
    "maxContains" => Exonerate.Filter.MaxContains,
    "minContains" => Exonerate.Filter.MinContains,
    "unevaluatedItems" => Exonerate.Filter.UnevaluatedItems
  }

  @doc """
  Returns the module for an array filter.

  ## Examples

      iex> Exonerate.Modules.array_filter("items")
      Exonerate.Filter.Items

      iex> Exonerate.Modules.array_filter("uniqueItems")
      Exonerate.Filter.UniqueItems
  """
  @spec array_filter(String.t()) :: module() | nil
  def array_filter(filter_name), do: @array_modules[filter_name]

  @doc "Returns all array filter modules."
  def array_modules, do: @array_modules

  # ============================================================================
  # Format Modules
  # ============================================================================

  @format_modules %{
    "duration" => Exonerate.Formats.Duration,
    "email" => Exonerate.Formats.Email,
    "idn-email" => Exonerate.Formats.IdnEmail,
    "hostname" => Exonerate.Formats.Hostname,
    "idn-hostname" => Exonerate.Formats.IdnHostname,
    "uri" => Exonerate.Formats.Uri,
    "uri-reference" => Exonerate.Formats.UriReference,
    "iri" => Exonerate.Formats.Iri,
    "iri-reference" => Exonerate.Formats.IriReference,
    "uri-template" => Exonerate.Formats.UriTemplate,
    "json-pointer" => Exonerate.Formats.JsonPointer,
    "relative-json-pointer" => Exonerate.Formats.RelativeJsonPointer,
    "regex" => Exonerate.Formats.Regex
  }

  @builtin_formats Map.keys(@format_modules) ++
                     ~w(date-time date-time-utc date-time-tz date time ipv4 ipv6 uuid)

  @doc """
  Returns the module for a format validator.

  ## Examples

      iex> Exonerate.Modules.format("email")
      Exonerate.Formats.Email

      iex> Exonerate.Modules.format("uri")
      Exonerate.Formats.Uri
  """
  @spec format(String.t()) :: module() | nil
  def format(format_name), do: @format_modules[format_name]

  @doc "Returns all format module mappings."
  def format_modules, do: @format_modules

  @doc "Returns all built-in format names (including those without dedicated modules)."
  def builtin_formats, do: @builtin_formats

  # ============================================================================
  # Unified Lookup
  # ============================================================================

  @doc """
  Generic module lookup by category.

  ## Categories
  - `:type` - JSON type modules
  - `:combining` - Combining filter modules
  - `:object` - Object filter modules
  - `:array` - Array filter modules
  - `:format` - Format validator modules

  ## Examples

      iex> Exonerate.Modules.lookup(:type, "string")
      Exonerate.Type.String

      iex> Exonerate.Modules.lookup(:combining, "allOf")
      Exonerate.Combining.AllOf
  """
  @spec lookup(:type | :combining | :object | :array | :format, String.t()) :: module() | nil
  def lookup(:type, name), do: type(name)
  def lookup(:combining, name), do: combining(name)
  def lookup(:object, name), do: object_filter(name)
  def lookup(:array, name), do: array_filter(name)
  def lookup(:format, name), do: format(name)
end
