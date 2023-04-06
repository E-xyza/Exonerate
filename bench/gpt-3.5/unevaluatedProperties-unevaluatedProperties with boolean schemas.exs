defmodule :"unevaluatedProperties-unevaluatedProperties with boolean schemas-gpt-3.5" do
  def validate(value) when is_map(value) do
    case Map.has_key?(value, "foo") do
      true ->
        case Map.get(value, "foo") do
          val when is_binary(val) -> :ok
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
