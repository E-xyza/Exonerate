if Code.ensure_loaded?(Decimal) do
  defmodule Exonerate.Decimal do
    @moduledoc """
    Helper module for Decimal support in Exonerate.

    This module provides utilities for checking if decimal mode is enabled
    at a given schema location and for converting values to Decimal.

    ## Usage

    Enable decimal mode with the `:decimal` option:

        # All numeric locations use Decimal arithmetic
        Exonerate.function_from_string(:def, :validate, schema, decimal: :all)

        # Specific paths use Decimal arithmetic
        Exonerate.function_from_string(:def, :validate, schema,
          decimal: [at: ["/properties/price", "/properties/amount"]]
        )

    When decimal mode is enabled at a location:
    - `"type": "number"` values (float/integer) are converted to Decimal
    - `"type": "integer"` values are converted to Decimal
    - `"type": "string"` values are parsed as Decimal (validation error if invalid)
    - Numeric filters (minimum, maximum, multipleOf, etc.) use Decimal arithmetic
    """

    @doc """
    Checks if decimal mode is enabled at the given resource/pointer location.
    """
    def enabled?(resource, pointer, opts) do
      case Keyword.get(opts, :decimal) do
        nil -> false
        :all -> true
        config when is_list(config) -> path_matches?(resource, pointer, config)
        _ -> false
      end
    end

    defp path_matches?(resource, pointer, config) do
      at_paths = Keyword.get(config, :at, [])

      prefix =
        if String.starts_with?(resource, "exonerate://") do
          ""
        else
          resource
        end

      # Get the pointer path without the filter name (e.g., strip "/minimum")
      parent_pointer = JsonPtr.backtrack!(pointer)

      selector =
        parent_pointer
        |> JsonPtr.to_uri()
        |> to_string()
        |> String.replace_prefix("", prefix)

      selector in at_paths
    end

    @doc """
    Converts a value to Decimal. Returns {:ok, decimal} or {:error, reason}.
    """
    def convert(value) when is_integer(value), do: {:ok, Decimal.new(value)}
    def convert(value) when is_float(value), do: {:ok, Decimal.from_float(value)}

    def convert(value) when is_binary(value) do
      {:ok, Decimal.new(value)}
    rescue
      Decimal.Error -> {:error, "invalid decimal string"}
    end

    def convert(_), do: {:error, "cannot convert to decimal"}

    @doc """
    Converts a schema value (from JSON) to Decimal for comparison.
    Schema values can be numbers or strings.
    """
    def from_schema(value) when is_integer(value), do: Decimal.new(value)
    def from_schema(value) when is_float(value), do: Decimal.from_float(value)
    def from_schema(value) when is_binary(value), do: Decimal.new(value)

    @doc """
    Compares two Decimal values. Returns :lt, :eq, or :gt.
    """
    def compare(a, b), do: Decimal.compare(a, b)

    @doc """
    Computes the remainder of a / b.
    """
    def rem(a, b), do: Decimal.rem(a, b)

    @doc """
    Returns Decimal representing zero.
    """
    def zero, do: Decimal.new(0)
  end
end
