defmodule :"anyOf with base schema-gpt-3.5" do
  def validate(object)
      when is_map(object) and Map.has_key?(object, "type") and object["type"] == "string" do
    validate_string(object)
  end

  def validate(_) do
    {:error, "Invalid input"}
  end

  defp validate_string(object) do
    case Enum.any?(
           [
             fn
               %{"maxLength" => length} -> byte_size(object) <= length
               _ -> false
             end,
             fn
               %{"minLength" => length} -> byte_size(object) >= length
               _ -> false
             end
           ],
           fn validator -> validator end
         ) do
      true -> :ok
      false -> {:error, "Input does not match schema"}
    end
  end
end