defmodule :"contains-contains keyword validation-gpt-3.5" do
  elixir

  defmodule Validator do
    def validate(_) do
      :error
    end

    def validate(object) when is_map(object) do
      case Map.fetch(object, "contains") do
        {:ok, validation} ->
          case Map.fetch(validation, "minimum") do
            {:ok, minimum} when is_integer(minimum) and minimum >= 5 -> :ok
            _ -> :error
          end

        _ ->
          :error
      end
    end
  end
end
