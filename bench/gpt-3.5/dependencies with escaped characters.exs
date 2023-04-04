defmodule :"dependencies with escaped characters-gpt-3.5" do
  defmodule Validator do
    def validate(object) when is_map(object) do
      :ok
    end

    def validate(_) do
      :error
    end

    def validate_jsonschema(jsonschema) do
      case jsonschema do
        %{"type" => "object"} ->
          &Validator.validate/1

        %{"dependentSchemas" => dependent_schemas} ->
          dependent_schemas
          |> Enum.map(fn {name, schema} ->
            %{"name" => name, "validator" => Validator.validate_jsonschema(schema)}
          end)
          |> (&Validator.validate_dependent_schemas/1)

        %{"required" => required} ->
          &Validator.validate_required_fields/1

        %{"minProperties" => min_properties} ->
          &Validator.validate_min_properties/1

        other ->
          raise ArgumentError, "Unknown jsonschema directive: #{inspect(other)}"
      end
    end

    def validate_dependent_schemas(dependent_schemas, object) do
      Enum.reduce(dependent_schemas, :ok, fn %{"name" => name, "validator" => validator}, acc ->
        case Map.has_key?(object, name) do
          true ->
            case validator.(Map.get(object, name)) do
              :ok -> acc
              :error -> :error
            end

          false ->
            acc
        end
      end)
    end

    def validate_required_fields(required_fields, object) do
      case Enum.all?(required_fields, &Map.has_key?(object, &1)) do
        true -> :ok
        false -> :error
      end
    end

    def validate_min_properties(min_properties, object) do
      case Map.size(object) >= min_properties do
        true -> :ok
        false -> :error
      end
    end
  end

  def validate(json) do
    case Poison.decode(json) do
      %{} ->
        raise ArgumentError,
              "Empty json object!"

      decoded ->
        Validator.validate_jsonschema(decoded).(decoded)
    end
  end
end
