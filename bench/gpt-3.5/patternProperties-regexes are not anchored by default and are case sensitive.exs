defmodule :"patternProperties-regexes are not anchored by default and are case sensitive-gpt-3.5" do
  defmodule MySchema do
    def validate(%{}) do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  defmodule MyValidator do
    def validate(object) when is_map(object) do
      patterns = [{"^X_$", :string}] ++ Enum.map(0..99, fn num -> {"^#{num}$", :boolean} end)
      schema = %{"patternProperties" => Map.new([patterns])}
      check_schema(schema, object)
    end

    def validate(_) do
      :error
    end

    defp check_schema(schema, value) when is_map(schema) and is_map(value) do
      if map_size(schema) == 1 and Map.has_key?(schema, "patternProperties") do
        check_pattern_properties(schema["patternProperties"], value)
      else
        check_type(schema["type"], value)
      end
    end

    defp check_schema(_schema, _value) do
      :error
    end

    defp check_type("string", value) when is_binary(value) do
      :ok
    end

    defp check_type("number", value) when is_number(value) do
      :ok
    end

    defp check_type("integer", value) when is_integer(value) do
      :ok
    end

    defp check_type("boolean", true) or check_type("boolean", false) do
      :ok
    end

    defp check_type("null", nil) do
      :ok
    end

    defp check_type("object", value) when is_map(value) do
      :ok
    end

    defp check_type("array", value) when is_list(value) do
      :ok
    end

    defp check_type(_type, _value) do
      :error
    end

    defp check_pattern_properties(schema, value) when is_map(schema) and is_map(value) do
      result = :ok

      Enum.each(Map.keys(schema), fn pattern ->
        matched = Enum.any?(Map.keys(value), &String.match?(&1, ~r/#{pattern}/))
        schema_type = schema[pattern]["type"]

        if matched do
          if check_type(schema_type, Map.get(value, pattern)) == :error do
            result = :error
          end
        end
      end)

      result
    end

    defp check_pattern_properties(_schema, _value) do
      :error
    end
  end
end
