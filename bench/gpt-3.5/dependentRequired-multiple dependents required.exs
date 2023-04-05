defmodule :"multiple dependents required-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "quux") do
      true ->
        case Map.get(object, "quux") do
          ["foo", "bar"] -> :ok
          _ -> :error
        end

      false ->
        :ok
    end
  end

  def validate(_) do
    :error
  end
end
