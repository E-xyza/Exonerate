defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent properties" do
  
defmodule Validator do
  def validate(object) when is_map(object) and map_size(object) > 0, do: :ok
  def validate(_), do: :error
end

defmodule JsonSchema do
  @json_schema %{
    "properties": %{
      "foo": %{"type": "string"}
    },
    "type": "object",
    "unevaluatedProperties": false
  }

  def decode(json) do
    # Decode the JSON value
    {:ok, decoded} = Poison.decode(json)

    # Use the decoded JSON value to create the validation function
    create_validation_function(decoded)
  end

  defp create_validation_function(%{"type" => "object", "properties" => properties} = schema) do
    # Create a list of clauses for the match statement
    clauses = for {key, sub_schema} <- properties do
      {key, create_validation_function(sub_schema)}
    end

    # Create the function to validate maps
    function = quote do
      def validate(map) when is_map(map) and do_validate(unquote(clauses), map), do: :ok
      def validate(_), do: :error

      defp do_validate([], map), do: true
      defp do_validate([ {key, validate_function} | tail ], map) do
        # If the key is not present, the validation fails
        cond do
          not Map.has_key?(map, key) ->
            false

          # Otherwise, validate the value and continue with the next clause
          validate_function.(Map.get(map, key)) and do_validate(tail, map) ->
            true

          # If validation fails, stop and return false
          true ->
            false
        end
      end
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "object"}) do
    # Create the function to validate empty maps
    function = quote do
      def validate(map) when is_map(map) and map_size(map) == 0, do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "array", "items" => sub_schema}) do
    # Create the function to validate arrays
    function = quote do
      def validate(array) when is_list(array) and do_validate(unquote(create_validation_function(sub_schema)), array), do: :ok
      def validate(_), do: :error

      defp do_validate(_, []), do: true
      defp do_validate(validate_function, [ head | tail ]) do
        # Validate the head and continue with the tail
        validate_function.(head) and do_validate(validate_function, tail)
      end
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "string"}) do
    # Create the function to validate strings
    function = quote do
      def validate(string) when is_binary(string), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "number"}) do
    # Create the function to validate numbers
    function = quote do
      def validate(number) when is_integer(number) or is_float(number), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "boolean"}) do
    # Create the function to validate booleans
    function = quote do
      def validate(boolean) when boolean in [true, false], do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"not" => schema}) do
    # Create the function to validate the inverse of a schema
    validate_function = create_validation_function(schema)
    function = quote do
      def validate(value) when not(unquote(validate_function).(value)), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"anyOf" => schemas}) do
    # Create the function that validates any of the schemas
    validate_functions = for schema <- schemas do
      create_validation_function(schema)
    end

    function = quote do
      def validate(value) when Enum.any?(unquote(validate_functions), &.&.(value)), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"allOf" => schemas}) do
    # Create the function that validates all of the schemas
    validate_functions = for schema <- schemas do
      create_validation_function(schema)
    end

    function = quote do
      def validate(value) when Enum.all?(unquote(validate_functions), &.&.(value)), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"enum" => values}) do
    function = quote do
      def validate(value) when Enum.member?(unquote(values), value), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"oneOf" => schemas}) do
    # Create the function that validates exactly one of the schemas
    validate_functions = for schema <- schemas do
      create_validation_function(schema)
    end

    function = quote do
      def validate(value) when Enum.count(unquote(validate_functions), &.&.(value)) == 1, do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"type" => "null"}) do
    # Create the function to validate null values
    function = quote do
      def validate(nil), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp create_validation_function(%{"$ref" => ref}) do
    # Create the function that refers to another schema
    function = quote do
      def validate(value) when unquote(create_validation_function(resolve_reference(ref))).(value), do: :ok
      def validate(_), do: :error
    end

    # Return the created function
    Macro.expand(function, __ENV__)
  end

  defp resolve_reference(ref) do
    # Here you would resolve the reference to the actual schema, but we're ignoring this for now
    %{
      "type": "string"
    }
  end
end

end
