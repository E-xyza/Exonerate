defmodule :"patternProperties-patternProperties with boolean schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    pattern_properties = object |> Map.keys() |> Enum.filter(&String.match?(&1, ~r/^(b|f)\..*/))

    if pattern_properties == [] do
      :ok
    else
      pattern_errors =
        Enum.map(pattern_properties, fn property ->
          if String.match?(property, ~r/^b\..*/) do
            case Map.get(object, String.replace_prefix(property, "b.", "")) do
              false -> :ok
              _ -> :error
            end
          else
            case Map.get(object, String.replace_prefix(property, "f.", "")) do
              true -> :ok
              _ -> :error
            end
          end
        end)

      if Enum.all?(pattern_errors, &(&1 == :ok)) do
        :ok
      else
        :error
      end
    end
  end

  def validate(_) do
    :error
  end
end